//
//  ViewController.swift
//  FirestoreExample
//
//  Created by Parkjonghyun on 2020/07/18.
//  Copyright © 2020 jonghyun. All rights reserved.
//

import UIKit
import Mapbox
import FirebaseFirestore

// 39.005832, 125.789699

//protocol UpdateLocation {
//    func update(lat: CLLocationDegrees, lng: CLLocationDegrees)
//}

class ViewController: UIViewController {
    var locationManager : CLLocationManager!
    private var mapView: MGLMapView? = nil
    private var annotation: MGLPointAnnotation? = nil
    private let db = Firestore.firestore()
    private var annotationMap = [String : MGLAnnotation]()
    private var userName: String = "" // insert your name
    private var pin: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        initializeLocationManager()
        initializeMapView()
        
        readAllFirebaseLocation()
    }
    
    private func initializeMapView() {
        let url = URL(string: "mapbox://styles/mapbox/streets-v11")
        mapView = MGLMapView(frame: view.bounds, styleURL: url)
        self.mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.mapView?.delegate = self
        if let map = mapView {
            view.addSubview(map)
        }
    }
    
    private func initializeLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() //권한 요청
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    private func updateLocation() {
        print("> map size \(annotationMap.count)")
        if let annotaitonList = mapView?.annotations {
            mapView?.removeAnnotations(annotaitonList)
        }
        
        mapView?.updateUserLocationAnnotationView()
        
        for (key, value) in annotationMap {
            if (pin) {
                if userName == value.title! {
                    self.mapView?.setCenter(CLLocationCoordinate2D(latitude: value.coordinate.latitude, longitude: value.coordinate.longitude), zoomLevel: 15, animated: false)
                    pin = false
                }
            }
            
            mapView?.addAnnotation(value)
        }
    }
    
    private func readAllFirebaseLocation() {
        db.collection("location").addSnapshotListener { querySnapshot, error in
           guard let snapshot = querySnapshot else {
                     print("Error fetching snapshots: \(error!)")
                     return
                 }
                 snapshot.documentChanges.forEach { diff in
                     if (diff.type == .added) {
                        print("add: \(diff.document.data())")
                        let lat = diff.document.data()["lat"] as? String
                        let lng = diff.document.data()["lng"] as? String
                        let name = diff.document.data()["name"] as? String
                        
                        self.addAnnotation(lat: lat?.toDouble() ?? 0.0, lng: lng?.toDouble()! ?? 0.0, name: name ?? "버그")
                     }
                     if (diff.type == .modified) {
                         print("modify: \(diff.document.data())")
                         let lat = diff.document.data()["lat"] as? String
                         let lng = diff.document.data()["lng"] as? String
                         let name = diff.document.data()["name"] as? String
                         
                         self.addAnnotation(lat: lat?.toDouble() ?? 0.0, lng: lng?.toDouble()! ?? 0.0, name: name ?? "버그")
                     }
                     if (diff.type == .removed) {
                         print("remove: \(diff.document.data())")
                     }
                 }
        }
    }
    
    private func addAnnotation(lat: Double, lng: Double, name: String) {
        let otherAnnotation = MGLPointAnnotation()
        otherAnnotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        otherAnnotation.title = name
        otherAnnotation.subtitle = name
        self.annotationMap[name] = otherAnnotation
        updateLocation()
    }
    
    private func updateFirebaseMyLocation(location: CLLocationCoordinate2D) {
        db.collection("location").document("").setData([
            "name": userName,
            "lat": "\(location.latitude)",
            "lng": "\(location.longitude)"
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
}


extension ViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
    }
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = manager.location?.coordinate {
            updateFirebaseMyLocation(location: coordinate)
        }
    }
}


extension String {
    func toDouble() -> Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
}
