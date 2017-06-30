/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Firebase

public extension FirebaseApp {
    
    public static func random(with ref: DatabaseReference) -> FirebaseApp {
        let uuid = UUID().uuidString
        let randomName = uuid.replacingOccurrences(of: "-", with: "")
        let options = ref.database.app!.options
        FirebaseApp.configure(name: randomName, options: options)
        return FirebaseApp.app(name: randomName)!
    }
    
}
