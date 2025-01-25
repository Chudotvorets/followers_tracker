//
//  ViewController.swift
//  followers_tracker
//
//  Created by dev on 24/01/2025.
//

import UIKit
import CoreData



// MARK: - ViewController
class SubscriberViewController: UIViewController {

    let context: NSManagedObjectContext = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Unable to cast UIApplication delegate to AppDelegate")
        }
        return appDelegate.persistentContainer.viewContext
    }()

    var currentSubscribers: [SubscriberModel] = []
    var previousSubscribers: [NSManagedObject] = []
    var newSubscribers: [SubscriberModel] = []
    var unsubscribed: [NSManagedObject] = []

    // UI Elements
    let tableView = UITableView()
    let segmentControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Current", "New", "Unsubscribed"])
        control.selectedSegmentIndex = 0
        return control
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Setup UI
        setupUI()

        // Load previous subscribers from Core Data
        loadPreviousSubscribers()

        // Load current subscribers from mock file
        loadSubscribersFromMock(fileName: "mock")

        // Compare and update UI
        let changes = compareSubscribers()
        newSubscribers = changes.new
        unsubscribed = changes.unsubscribed

        // Save the new state to Core Data
        saveSubscribersToCoreData()

        // Reload table view
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // MARK: - Setup UI
    func setupUI() {
        // Add segment control
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        view.addSubview(segmentControl)
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])

        // Add table view
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc func segmentChanged() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // MARK: - Load Subscribers from Mock
    func loadSubscribersFromMock(fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            print("Mock file not found")
            
            return
        }
        do {
            let data = try Data(contentsOf: url)
            currentSubscribers = try JSONDecoder().decode([SubscriberModel].self, from: data)
        } catch DecodingError.keyNotFound(let key, let context) {
            print("Missing key: \(key), context: \(context)")
        } catch DecodingError.typeMismatch(let type, let context) {
            print("Type mismatch for type: \(type), context: \(context)")
        } catch DecodingError.dataCorrupted(let context) {
            print("Data corrupted: \(context)")
        } catch {
            print("Unknown error loading mock data: \(error)")
        }
    }

    // MARK: - Core Data Operations
    func loadPreviousSubscribers() {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SubscriberEntity")
        do {
            previousSubscribers = try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch subscribers: \(error)")
        }
    }

    func saveSubscribersToCoreData() {
        // Удаление старых данных
        for object in previousSubscribers {
            context.delete(object)
        }

        // Сохранение новых данных
        for subscriber in currentSubscribers {
            guard let entity = NSEntityDescription.entity(forEntityName: "SubscriberEntity", in: context) else {
                print("Entity 'SubscriberEntity' not found in Core Data model")
                return
            }
            let newSubscriber = NSManagedObject(entity: entity, insertInto: context)
            newSubscriber.setValue(subscriber.id, forKey: "id")
            newSubscriber.setValue(subscriber.name, forKey: "name")
            newSubscriber.setValue(subscriber.gender, forKey: "gender")
        }

        do {
            try context.save()
        } catch {
            print("Failed to save subscribers: \(error)")
        }
    }


    // MARK: - Compare Subscribers
    func compareSubscribers() -> (new: [SubscriberModel], unsubscribed: [NSManagedObject]) {
        var newSubscribers: [SubscriberModel] = []
        var unsubscribed: [NSManagedObject] = []

        let previousIDs = Set(previousSubscribers.map { $0.value(forKey: "id") as? String ?? "" })
        let currentIDs = Set(currentSubscribers.map { $0.id })

        // Find new subscribers
        for subscriber in currentSubscribers {
            if !previousIDs.contains(subscriber.id) {
                newSubscribers.append(subscriber)
            }
        }

        // Find unsubscribed
        for subscriber in previousSubscribers {
            if let id = subscriber.value(forKey: "id") as? String, !currentIDs.contains(id) {
                unsubscribed.append(subscriber)
            }
        }

        return (newSubscribers, unsubscribed)
    }
}

// MARK: - UITableViewDataSource
extension SubscriberViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            return currentSubscribers.count
        case 1:
            return newSubscribers.count
        case 2:
            return unsubscribed.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

            switch segmentControl.selectedSegmentIndex {
            case 0:
                let subscriber = currentSubscribers[indexPath.row]
                cell.textLabel?.text = "\(subscriber.name) | ID: \(subscriber.id) | Gender: \(subscriber.gender)"
            case 1:
                let subscriber = newSubscribers[indexPath.row]
                cell.textLabel?.text = "\(subscriber.name) | ID: \(subscriber.id) | Gender: \(subscriber.gender)"
            case 2:
                let subscriber = unsubscribed[indexPath.row]
                let name = subscriber.value(forKey: "name") as? String ?? "Unknown"
                let id = subscriber.value(forKey: "id") as? String ?? "Unknown"
                let gender = subscriber.value(forKey: "gender") as? String ?? "Unknown"
                cell.textLabel?.text = "\(name) | ID: \(id) | Gender: \(gender)"
            default:
                cell.textLabel?.text = ""
            }

            return cell
        }
}

