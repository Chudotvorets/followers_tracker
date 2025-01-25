//
//  CoreData.swift
//  followers_tracker
//
//  Created by dev on 24/01/2025.
//

//import CoreData
//import UIKit
//
//func saveSubscribersToCoreData(subscribers: [Subscriber]) {
//    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
//    let context = appDelegate.persistentContainer.viewContext
//
//    // Очистить предыдущие данные
//    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SubscriberEntity")
//    if let result = try? context.fetch(fetchRequest) {
//        for object in result {
//            context.delete(object)
//        }
//    }
//
//    // Сохранить новые данные
//    for subscriber in subscribers {
//        let entity = NSEntityDescription.entity(forEntityName: "SubscriberEntity", in: context)!
//        let newSubscriber = NSManagedObject(entity: entity, insertInto: context)
//        newSubscriber.setValue(subscriber.id, forKey: "id")
//        newSubscriber.setValue(subscriber.name, forKey: "name")
//        newSubscriber.setValue(subscriber.gender, forKey: "gender")
//    }
//
//    do {
//        try context.save()
//        print("Subscribers saved to Core Data")
//    } catch {
//        print("Failed to save subscribers: \(error)")
//    }
//}
