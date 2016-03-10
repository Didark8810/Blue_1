//
//  ViewController.swift
//  blue_1
//
//  Created by diego bernal on 23/02/16.
//  Copyright © 2016 diego bernal. All rights reserved.
//

import UIKit

import CoreBluetooth

class ViewController: UIViewController,CBCentralManagerDelegate ,CBPeripheralDelegate, UITextFieldDelegate{

    @IBOutlet weak var txtInfoEnvia: UITextField!
    @IBOutlet weak var InfoRecibe: UITextView!
    @IBOutlet weak var lblEstado: UILabel!
    @IBOutlet weak var btn_Limpiar: UIButton!
    
    var manager: CBCentralManager!
    var miBand : CBPeripheral!

    
    var ModoCadena:Bool = false
    
    var TramaCadena:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager = CBCentralManager(delegate: self, queue: nil)
        self.txtInfoEnvia.delegate=self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print(peripheral.name)
        if(peripheral.name=="FR_00000001")
        {
            self.miBand = peripheral
            self.miBand.delegate = self
            manager.stopScan()
            manager.connectPeripheral(self.miBand, options: nil)
            lblEstado.text="conectado"
        }
    }
    
    
    
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let servicePeriferical = peripheral.services as[CBService]!
        {
            for service in servicePeriferical
            {
                peripheral.discoverCharacteristics(nil, forService: service)
            }
        }
    }
    
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let caracteristicas = service.characteristics as [CBCharacteristic]!
        {
            for cc in caracteristicas
            {
                print("El valor de cara es :\(cc.UUID.UUIDString)")
                if(cc.UUID.UUIDString=="FFE1")
                {
                    print("encontre algo :  ")
                    peripheral.readValueForCharacteristic(cc)
                    peripheral.setNotifyValue(true, forCharacteristic: cc)
                    let str = "Bluetooth On"
                    let data = str.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
                    peripheral.writeValue(data!, forCharacteristic: cc, type: CBCharacteristicWriteType.WithoutResponse)
                }
            }
        }
        
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print(" se putio \(error?.localizedDescription)")
    }
    
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("error: \(error?.localizedDescription)---- nombre \(characteristic.UUID.UUIDString)---- valor \(characteristic.value)")
        
        
    }
    
    
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        let resstr = NSString(data: characteristic.value!, encoding: NSUTF8StringEncoding)
        
        print("val de algo : \(resstr)")
        InfoRecibe.text = (resstr as! String )+"\n"
        
        let res:String = NSString(data: characteristic.value!, encoding: NSUTF8StringEncoding) as! String
        print(res)
        if(res.containsString("ST")==true)
        {
            ModoCadena=true
            TramaCadena=res
        }
        else
        {
            if (ModoCadena)
            {
                TramaCadena+=res
                if(res.containsString("$")==true)
                {
                    ModoCadena=false
                     InfoRecibe.text =  (TramaCadena)+"\n"
                    let ListaVector = TramaCadena.componentsSeparatedByString(";")
                    if(ListaVector.count==21)
                    {
                        print("Trama PROCESADA : \(TramaCadena)")
                        //GuardarTransmision(ListaVector)
                        //AnalizarTrama(ListaVector)
                    }
                    else
                    {
                        print("Trama NO PROCESADA : \(TramaCadena)")
                    }
                }
            }
            else
            {
                TramaCadena = ""
                print("Trama NORMAL : \(res)")
            }
        }

        
    }
    
    
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        let arrayOfServices: [CBUUID] = [CBUUID(string: "FFE0")]
        let dictionaryOfOptions = [CBCentralManagerScanOptionAllowDuplicatesKey : true]
        manager.scanForPeripheralsWithServices(arrayOfServices, options: dictionaryOfOptions)
    }
    
    
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.delegate=self
        peripheral.discoverServices(nil)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        var consoleMsg=""
        
        switch (central.state)
        {
        case .PoweredOff:
            consoleMsg="apaga"
            let alertController = UIAlertController(title: "Control de motos", message:"El bluetooth esta apagado, activalo por favor!!", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Aceptar", style: UIAlertActionStyle.Default,handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        case .PoweredOn:
            consoleMsg = "prende"
            let arrayOfServices: [CBUUID] = [CBUUID(string: "FFE0")]
            let dictionaryOfOptions = [CBCentralManagerScanOptionAllowDuplicatesKey : true]
            manager.scanForPeripheralsWithServices(arrayOfServices, options: dictionaryOfOptions)
            //lblEstado.text="conecte"
        case .Resetting:
            consoleMsg="Reset"
        case .Unauthorized:
            consoleMsg="Unat"
        case .Unknown:
            consoleMsg="Unk"
        case .Unsupported:
            consoleMsg="unsupp"
            
        }
        print("\(consoleMsg)")
    }
    
    
    
    @IBAction func btn_Desconectar(sender: AnyObject) {
        manager.cancelPeripheralConnection(miBand)
        lblEstado.text="desconecte"
    
    }
    
    
    
    @IBAction func btn_enviar(sender: AnyObject) {
        
        if miBand.state == CBPeripheralState.Connected {
            let Servicios:[CBService] = miBand.services!
            if Servicios.count>0
            {
                for servicee in Servicios
                {
                    if let caracteristicas = servicee.characteristics as [CBCharacteristic]!
                    {
                        for cc in caracteristicas
                        {
                            if(cc.UUID.UUIDString=="FFE1")
                            {
                                let str = txtInfoEnvia.text
                                let data = str!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
                                miBand.writeValue(data!, forCharacteristic: cc, type: CBCharacteristicWriteType.WithoutResponse)
                                self.txtInfoEnvia.resignFirstResponder();
                            }
                        }
                    }
                }
            }
            
            
            
            
            
        }
    
    
        
    
    
    }
    
    @IBAction func btn_Conectar(sender: AnyObject) {
        let arrayOfServices: [CBUUID] = [CBUUID(string: "FFE0")]
        let dictionaryOfOptions = [CBCentralManagerScanOptionAllowDuplicatesKey : true]
        manager.scanForPeripheralsWithServices(arrayOfServices, options: dictionaryOfOptions)
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == txtInfoEnvia
        {
            txtInfoEnvia.resignFirstResponder()
        }
        
        return true
    }

    @IBAction func limp(sender: AnyObject) {
        InfoRecibe.text=""
    }
    
}

