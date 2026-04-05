export class EventDispatcher<T> {
  private observers: Array<T> = [];

  add(observer: T): void {
    if (this.observers.indexOf(observer) < 0) {
      this.observers.push(observer);
    }
  }

  remove(observer: T): void {
    this.observers = this.observers.filter((item: T) => item !== observer);
  }

  snapshot(): Array<T> {
    return this.observers.slice();
  }
}
