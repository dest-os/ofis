sealed class AresResult<T> {
  const AresResult();
}

class AresSuccess<T> extends AresResult<T> {
  const AresSuccess(this.value);

  final T value;
}

class AresFailure<T> extends AresResult<T> {
  const AresFailure(this.message);

  final String message;
}
