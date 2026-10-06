import '../../domain/runtime/runtime_task.dart';
import '../../domain/runtime/execution_context.dart';
import '../../domain/runtime/runtime_result.dart';
import '../../domain/runtime/runtime_state.dart';
import '../../domain/runtime/checkpoint.dart';
import '../../domain/events/event_envelope.dart';
import '../../domain/events/event_type.dart';
import '../events/event_publisher.dart';
import 'checkpoint_repository.dart';
import 'lease_repository.dart';
import 'scheduler.dart';
import 'resource_runtime.dart';
import 'agent_manager_runtime.dart';
import 'worker_runtime.dart';
import 'result_pipeline.dart';
import 'paid_ai_runtime_gate.dart';

class RuntimeKernel {
  RuntimeKernel({
    required RuntimeScheduler scheduler,
    required AgentManagerRuntime agentManager,
    required WorkerRuntime worker,
    required ResourceRuntime resources,
    required CheckpointRepository checkpoints,
    required LeaseRepository leases,
    required RuntimeResultPipeline resultPipeline,
    required EventPublisher eventPublisher,
    PaidAiRuntimeGate? aiGate,
  })  : _scheduler = scheduler,
        _agentManager = agentManager,
        _worker = worker,
        _resources = resources,
        _checkpoints = checkpoints,
        _leases = leases,
        _resultPipeline = resultPipeline,
        _eventPublisher = eventPublisher,
        _aiGate = aiGate ?? const PaidAiRuntimeGate();

  final RuntimeScheduler _scheduler;
  final AgentManagerRuntime _agentManager;
  final WorkerRuntime _worker;
  final ResourceRuntime _resources;
  final CheckpointRepository _checkpoints;
  final LeaseRepository _leases;
  final RuntimeResultPipeline _resultPipeline;
  final EventPublisher _eventPublisher;
  final PaidAiRuntimeGate _aiGate;

  Future<void> submit(RuntimeTask task) async {
    task.state = RuntimeState.ready;
    await _scheduler.schedule(task);
    await _emit(EventType.taskStatusChanged, task, 'READY');
  }

  Future<RuntimeTask?> runNext() async {
    final task = await _scheduler.next();
    if (task == null) return null;

    final snapshot = await _resources.snapshot();
    if (!_resources.mayStartWork(snapshot)) {
      task.state = RuntimeState.paused;
      await _checkpoint(task);
      await _emit(EventType.taskStatusChanged, task, 'PAUSED');
      return task;
    }

    final agent = await _agentManager.acquireWorker(taskId: task.task.id.value);
    if (agent == null) {
      task.state = RuntimeState.paused;
      task.lastError = 'Uygun çalışan bulunamadı.';
      await _checkpoint(task);
      return task;
    }

    task.workerId = agent.id.value;
    task.attempt += 1;
    task.state = RuntimeState.running;
    await _emit(EventType.agentStarted, task, 'RUNNING');

    try {
      final context = ExecutionContext(
        runId: '${task.task.id.value}-${task.attempt}',
        taskId: task.task.id.value,
        startedAt: DateTime.now(),
        agentId: agent.id.value,
      );
      final raw = await _worker.execute(context);
      final result = await _resultPipeline.normalize(raw);

      if (result.status == RuntimeResultStatus.waitingApproval) {
        task.state = RuntimeState.waitingApproval;
      } else if (result.status == RuntimeResultStatus.paused) {
        task.state = RuntimeState.paused;
      } else if (result.status == RuntimeResultStatus.success) {
        task.state = RuntimeState.stopped;
      } else {
        task.state = RuntimeState.failed;
        task.lastError = result.error;
      }

      await _checkpoint(task);
      await _emit(EventType.agentCompleted, task, task.state.value);
      return task;
    } finally {
      await _agentManager.releaseWorker(
        taskId: task.task.id.value,
        agentId: agent.id.value,
      );
    }
  }

  Future<void> pause(RuntimeTask task) async {
    task.state = RuntimeState.paused;
    await _worker.pause(task.task.id.value);
    await _checkpoint(task);
  }

  Future<void> cancel(RuntimeTask task) async {
    task.state = RuntimeState.stopped;
    await _worker.cancel(task.task.id.value);
    await _scheduler.cancel(task.task.id.value);
    await _checkpoint(task);
  }

  Future<void> _checkpoint(RuntimeTask task) async {
    await _checkpoints.save(
      RuntimeCheckpoint(
        id: '${task.task.id.value}-${task.attempt}-${DateTime.now().microsecondsSinceEpoch}',
        taskId: task.task.id.value,
        runId: '${task.task.id.value}-${task.attempt}',
        createdAt: DateTime.now(),
        state: task.state.value,
        attempt: task.attempt,
      ),
    );
  }

  Future<void> _emit(EventType type, RuntimeTask task, String state) async {
    await _eventPublisher.publish(
      EventEnvelope(
        id: '${task.task.id.value}-${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        createdAt: DateTime.now(),
        source: 'runtime_kernel',
        taskId: task.task.id.value,
        agentId: task.workerId,
        payload: <String, Object?>{
          'state': state,
          'attempt': task.attempt,
        },
      ),
    );
  }
}
