import UIKit
import CoreBluetooth

let kServiceUuid        = CBUUID(string: "3CB52165-FC39-41A6-A697-77060F43D447")
let kCharacteristicUuid = CBUUID(string: "B4705BFB-2976-4D19-9A29-3FBF4EC8622E")

class ViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView! { didSet{
        tableView.dataSource = self
    }}
    
    lazy var peripheralManager: CBPeripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    lazy var service = { () -> CBMutableService in
        let v = CBMutableService(type: kServiceUuid, primary: true)
        let characteristic = CBMutableCharacteristic(
            type: kCharacteristicUuid,
            properties: [.read, .write, .notify],
            value: nil,
            permissions: [.readEncryptionRequired, .writeEncryptionRequired]
        )
        v.characteristics = [characteristic]
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = peripheralManager
    }
    
    var logs: [String] = []
    func addLog(_ text: String) {
        print(text)
        logs.append(text)
        tableView.reloadData()
    }
}

extension ViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else { return }
        addLog("PM DidUpdateState:.poweredOn")
        
        peripheral.add(service)
        peripheral.startAdvertising([
            CBAdvertisementDataLocalNameKey: "secure_ble_test",
            CBAdvertisementDataServiceUUIDsKey: [kServiceUuid],
        ])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard error == nil else { addLog("PM DidStartAdvertising:\(error!)"); return }
        addLog("PM DidStartAdvertising")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else { addLog("PM didAdd service error: \(error!)"); return }
        addLog("PM didAdd service:\(service.uuid)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        requests.forEach{ request in
            addLog("PM didReceiveWrite characteristic:\(request.characteristic.uuid)")
            peripheral.respond(to: request, withResult: .success)
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            ?? UITableViewCell(style: .value1, reuseIdentifier: "cell")
        
        cell.textLabel?.text = logs[indexPath.row]
        
        return cell
    }
}
