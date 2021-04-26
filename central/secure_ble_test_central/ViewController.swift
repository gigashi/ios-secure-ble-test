import UIKit
import CoreBluetooth

let kServiceUuid        = CBUUID(string: "3CB52165-FC39-41A6-A697-77060F43D447")
let kCharacteristicUuid = CBUUID(string: "B4705BFB-2976-4D19-9A29-3FBF4EC8622E")

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView! { didSet{
        tableView.dataSource = self
    }}
    
    private lazy var centralManager = CBCentralManager(delegate: self, queue: nil)
    var peripheral: CBPeripheral? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        
        _ = centralManager
    }
    
    @IBAction func onClickWriteButton(_ sender: UIButton) {
        guard let peripheral = self.peripheral else { return }
        peripheral.printDescription()
        writeTest(peripheral: peripheral)
    }
    
    var logs: [String] = []
    func addLog(_ text: String) {
        print(text)
        logs.append(text)
        tableView.reloadData()
    }
    
    func writeTest(peripheral: CBPeripheral) {
        guard let service = (peripheral.services?.first{$0.uuid == kServiceUuid}) else { return }
        guard let characteristic = (service.characteristics?.first{$0.uuid == kCharacteristicUuid}) else { return }
        
        peripheral.writeValue(Data([0x00]), for: characteristic, type: .withResponse)
    }
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        addLog("centralManager DidUpdate State:\(central.state)")
        guard central.state == .poweredOn else { return }
        guard !centralManager.isScanning else { return }
        
        centralManager.scanForPeripherals(withServices: [kServiceUuid])
        addLog("scanForPeripherals:\([kServiceUuid])")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        centralManager.retrieveConnectedPeripherals(withServices: [kServiceUuid]).forEach{ peripheral in
            addLog("[retrieveConnectedPeripherals \(peripheral.name ?? "no name") - \(peripheral.identifier)]")
        }
        
        centralManager.retrievePeripherals(withIdentifiers: [peripheral.identifier]).forEach{ peripheral in
            addLog("[retrievePeripherals \(peripheral.name ?? "no name") - \(peripheral.identifier)]")
        }
        
        self.peripheral = peripheral // 参照保持
        centralManager.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        addLog("centralManager didConnect peripheral:\(peripheral)")
        
        peripheral.delegate = self
        peripheral.discoverServices([])
    }
}

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        addLog("peripheral didDiscoverServices")
        guard let service = (peripheral.services?.first{$0.uuid == kServiceUuid}) else { return }
        
        peripheral.discoverCharacteristics([], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        addLog("peripheral didDiscoverCharacteristicsFor")
        
        peripheral.printCharacteristics()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        addLog("peripheral didWriteValueFor error:\(error)")
    }
}

extension CBPeripheral {
    func printServices() {
        services?.forEach{ service in
            print("[\(name ?? "no name") - \(service.uuid)]")
        }
    }
    
    func printCharacteristics() {
        services?.forEach{ service in
            service.characteristics?.forEach{ characteristic in
                print("[\(name ?? "no name") - \(service.uuid) - \(characteristic.uuid)]")
            }
        }
    }
    
    func printDescription() {
        let peripheralName = name ?? "no name"
        print("peripheral[\(peripheralName)] state:\(state)")
        print("peripheral[\(peripheralName)] identifier:\(identifier)")
        print("peripheral[\(peripheralName)] ancsAuthorized:\(ancsAuthorized)")
        print("peripheral[\(peripheralName)] canSendWriteWithoutResponse:\(canSendWriteWithoutResponse)")
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
