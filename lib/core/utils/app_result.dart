sealed class AppResult<T> {
  const AppResult();
}

class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.data);
  final T data;
}

class AppFailure<T> extends AppResult<T> {
  const AppFailure(this.message);
  final String message;
}
