import Foundation

public func tryDecodable<T: Swift.Decodable>(_ json: JSON) -> Decoded<T> {
  guard
    // Convert Argo.JSON to primitive types, e.g. [String: Any].
    let primitive = json.toPrimitive(),
    // Convert the [String: Any] dictionary into `Data` for de-serialization by Swift.Decodable.

    let data = try? JSONSerialization.data(withJSONObject: primitive, options: [])
  // Any failure at this point is considered a de-serialization failure and will fail up to Argo.
  else { return .failure(.custom("Invalid JSON data")) }

  // Now that we have a Data type we can try to decode it as T
  do {
    let value = try JSONDecoder().decode(T.self, from: data)
    // If this succeeds we wrap it up in Argo.Decoded.
    return .success(value)
  } catch {
    // Again any failure at this point fails up the chain to Argo.
    return .failure(.custom("\(error)"))
  }
}

public func tryDecodable<T: Swift.Decodable>(_ json: JSON?) -> Decoded<T?> {
  guard let jsonData = json,
    // Convert Argo.JSON to primitive types, e.g. [String: Any].
    let primitive = jsonData.toPrimitive(),
    // Convert the [String: Any] dictionary into `Data` for de-serialization by Swift.Decodable.

    let data = try? JSONSerialization.data(withJSONObject: primitive, options: [])
  // Any failure at this point is considered a de-serialization failure and will fail up to Argo.
  else { return .success(nil) }

  // Now that we have a Data type we can try to decode it as T

  let value = try? JSONDecoder().decode(T.self, from: data)
  // If this succeeds we wrap it up in Argo.Decoded.
  return .success(value)
}

public func tryDecode<T: Swift.Decodable>(_ primitive: Any) -> T? {
  guard
    let data = try? JSONSerialization.data(withJSONObject: primitive, options: []),
    let value = try? JSONDecoder().decode(T.self, from: data)
  else { return nil }

  return value
}
