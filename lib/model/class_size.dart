/// This class holds information about the size of a class
class ClassSize {
  ClassSize({required this.size, required this.state});

  int size;
  ClassState state;
}

/// This enum indicates the state of the size of a class
enum ClassState { undersized, oversized, normal }
