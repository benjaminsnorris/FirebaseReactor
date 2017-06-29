/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Reactor

/// Simple protocol to help categorize events
public protocol FirebaseSeriousErrorEvent: Event {
    var error: Error { get }
}

/// Simple protocol to help categorize events
public protocol FirebaseMinorErrorEvent: Event {
    var error: Error { get }
}

/// Empty protocol to help categorize events
public protocol FirebaseDataEvent: Event { }


/**
 Generic event indicating that an object was added from Firebase and should be stored
 in the app state. The event is scoped to the object type that was added.
 - Parameters:
 - T:       The type of object that was added.
 - object:  The actual object that was added.
 */
public struct ObjectAdded<T>: FirebaseDataEvent {
    public var object: T
    public init(object: T) {
        self.object = object
    }
}

/**
 Generic event indicating that an object was changed in Firebase and should be modified
 in the app state. The event is scoped to the object type that was added.
 - Parameters:
 - T:       The type of object that was changed.
 - object:  The actual object that was changed.
 */
public struct ObjectChanged<T>: FirebaseDataEvent {
    public var object: T
    public init(object: T) {
        self.object = object
    }
}

/**
 Generic event indicating that an object was removed from Firebase and should be removed
 in the app state. The event is scoped to the object type that was added.
 - Parameters:
 - T:       The type of object that was removed.
 - object:  The actual object that was removed.
 */
public struct ObjectRemoved<T>: FirebaseDataEvent {
    public var object: T
    public init(object: T) {
        self.object = object
    }
}

/**
 Generic event indicating that an object has an error when parsing from a Firebase event.
 The event is scoped to the object type that was added.
 - Parameters:
 - T:       The type of object that produced the error
 - error:   An optional error indicating the problem that occurred
 */
public struct ObjectErrored<T>: Event, FirebaseMinorErrorEvent {
    public var error: Error
    public init(error: Error) {
        self.error = error
    }
}

/**
 Generic event indicating that an object was subscribed to in Firebase.
 The event is scoped to whatever you need to track the subscription status.
 - Parameters:
 - T:           The type of state that can be subscribed or not
 - subscribed:  Flag indicating subscription status
 */
public struct ObjectSubscribed<T>: FirebaseDataEvent {
    public var subscribed: Bool
    public var state: T
    public init(subscribed: Bool, state: T) {
        self.subscribed = subscribed
        self.state = state
    }
}

/**
 Event indicating that an object changed observed status.
 - Parameters:
 - path:     The path of the ref to the object
 - observed: Flag indicating when the object is being observed
 */
public struct ObjectObserved: FirebaseDataEvent {
    public var path: String
    public var observed: Bool
    public init(path: String, observed: Bool) {
        self.path = path
        self.observed = observed
    }
}

/**
 Event indicating that connection to Firebase changed status.
 - parameter connected: Bool value indicating whether the client is connected
 to Firebase
 */
public struct FirebaseConnectionChanged: FirebaseDataEvent {
    public var connected: Bool
    public init(connected: Bool) {
        self.connected = connected
    }
}
