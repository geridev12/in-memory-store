# InMemoryStore

## Overview

`InMemoryStore` is a Dart class that provides a **fast** and **efficient** in-memory storage mechanism. By leveraging Dart's `HashMap`, it ensures rapid data retrieval and insertion, making it ideal for temporary storage solutions.

## Features

- **Blazing-Fast Lookups**: Uses `HashMap` for **O(1) average time complexity** in insertions, deletions, and lookups.
- **Optional Expiration**: Supports automatic removal of entries after a specified duration.
- **Basic Store Operations**: Allows inserting, retrieving, checking existence, removing, and clearing stored entries.
- **Iterable Access**: Provides access to all stored keys and values.

## Usage

### Importing the Class

To use `InMemoryStore`, ensure you have the necessary import:

### Creating an Instance

You can create an instance of `InMemoryStore` with or without an expiration duration.

#### With Expiration Duration:

```dart
final store = InMemoryStore<String, String>.withExpiry(
  expiryDuration: Duration(seconds: 5),
);
```

In this setup, entries will automatically be removed after **5 seconds**.

#### Without Expiration Duration:

```dart
final store = InMemoryStore<String, String>.persistent();
```

Entries will persist until explicitly removed.

### Inserting Data

Use the `insert` method to add entries efficiently:

```dart
store.insert('username', 'JohnDoe');
```

If an expiration duration is set, the entry will be **automatically removed** after the specified time.

### Retrieving Data

Access stored values using the `get` method:

```dart
String? username = store.get('username');
if (username != null) {
  print('Username: $username');
} else {
  print('Key not found or expired');
}
```

This operation is **lightning-fast** due to the underlying `HashMap`.

### Checking for Key Existence

Verify if a key exists in the store:

```dart
if (store.containsKey('username')) {
  print('Key exists in store');
} else {
  print('Key does not exist');
}
```

### Removing Entries

Remove a specific entry:

```dart
store.remove('username');
```

Clear all entries:

```dart
store.clear();
```

### Accessing All Keys and Values

Retrieve all stored keys and values:

```dart
print('Keys: ${store.keys.toList()}');
print('Values: ${store.values.toList()}');
```

**Note:** `HashMap` does **not** maintain order, so retrieval order may vary.

## Why `HashMap` Makes This Store Incredibly Fast

The `InMemoryStore` class is built on **Dart's `HashMap`**, ensuring:

- **Instant Lookups:** Average time complexity of **O(1)** for insertions, deletions, and retrievals.
- **Optimized Memory Usage:** Efficiently manages data without unnecessary overhead.
- **Direct Key-Based Access:** Unlike a `Map` that may require iteration, `HashMap` allows for **near-instant retrieval**.
- **Dynamic Scaling:** Adjusts capacity dynamically for handling varying amounts of data.

### Why `HashMap` is the Best Choice for In-Memory Storage

Using a `HashMap` is the best approach for in-memory storage because:

- **Performance is Priority** – Faster than `Map` because it doesn't rely on iteration.
- **Unordered but Quick** – Order isn't guaranteed, but speed is maximized.
- **Efficient for Large Data Sets** – Doesn't slow down with increased entries.

For any scenario where **fast** and **efficient** key-value storage is required, `InMemoryStore` delivers top-tier performance thanks to its **HashMap-powered** architecture.

