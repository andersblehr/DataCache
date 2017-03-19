//
//  DataCacheTests.swift
//  DataCacheTests
//
//  Created by Anders Blehr on 13/03/2017.
//  Copyright © 2017 Anders Blehr. All rights reserved.
//

import XCTest
@testable import DataCache


class DataCacheTests: XCTestCase {
    
    var inMemory = true
    var bundle: Bundle! = nil
    
    var albums: [[String: Any]]! = nil
    var bands: [[String: Any]]! = nil
    var bandMembers: [[String: Any]]! = nil
    var musicians: [[String: Any]]! = nil
    
    
    override func setUp() {
        
        super.setUp()
        
        bundle = Bundle(for: type(of: self))
        
        let filePath = bundle.path(forResource: "bands", ofType: "json")
        let fileData = try! Data(contentsOf: URL(fileURLWithPath: filePath!))
        let jsonObject = try! JSONSerialization.jsonObject(with: fileData) as! [String: Any]
        
        bands = jsonObject["bands"] as! [[String: Any]]
        musicians = jsonObject["musicians"] as! [[String: Any]]
        bandMembers = jsonObject["band_members"] as! [[String: Any]]
        albums = jsonObject["albums"] as! [[String: Any]]
        
        JSONConverter.casing = .snake_case
        JSONConverter.dateFormat = .iso8601WithSeparators
    }
    
    
    override func tearDown() {
        
        super.tearDown()
        
        DataCache.mainContext.reset()
    }
    
    
    func testDateConversion() {
        
        let referenceTimeInterval = 966950880.0
        let referenceDate = Date(timeIntervalSince1970: referenceTimeInterval)
        
        JSONConverter.dateFormat = .iso8601WithSeparators
        XCTAssertEqual(Date(fromJSONValue: "2000-08-22T13:28:00Z").timeIntervalSince1970, referenceTimeInterval)
        XCTAssertEqual(referenceDate.toJSONValue() as! String, "2000-08-22T13:28:00Z")
        
        JSONConverter.dateFormat = .iso8601WithoutSeparators
        XCTAssertEqual(Date(fromJSONValue: "20000822T132800Z").timeIntervalSince1970, referenceTimeInterval)
        XCTAssertEqual(referenceDate.toJSONValue() as! String, "20000822T132800Z")
        
        JSONConverter.dateFormat = .timeIntervalSince1970
        XCTAssertEqual(Date(fromJSONValue: referenceTimeInterval).timeIntervalSince1970, referenceTimeInterval)
        XCTAssertEqual(referenceDate.toJSONValue() as! TimeInterval, referenceTimeInterval)
    }
    
    
    func testStringCaseConversion() {
        
        XCTAssertEqual(JSONConverter.convert(.fromJSON, string: "snake_case_attribute"), "snakeCaseAttribute")
        XCTAssertEqual(JSONConverter.convert(.toJSON, string: "snake_case_attribute"), "snake_case_attribute")
        XCTAssertEqual(JSONConverter.convert(.fromJSON, string: "camelCaseAttribute"), "camelCaseAttribute")
        XCTAssertEqual(JSONConverter.convert(.toJSON, string: "camelCaseAttribute"), "camel_case_attribute")
        XCTAssertEqual(JSONConverter.convert(.fromJSON, string: "description", qualifier: "snakeCase"), "snakeCaseDescription")
        XCTAssertEqual(JSONConverter.convert(.fromJSON, string: "camelCaseDescription"), "camelCaseDescription")
        XCTAssertEqual(JSONConverter.convert(.toJSON, string: "camelCaseDescription"), "description")
    }
    
    
    func testDictionaryCaseConversion() {
        
        let snake_case = bands.filter({ $0["name"] as! String == "Japan" })[0]
        let camelCase = JSONConverter.convert(.fromJSON, dictionary: snake_case, qualifier: "Band")
        let snake_case_roundtrip = JSONConverter.convert(.toJSON, dictionary: camelCase)
        
        XCTAssertEqual(camelCase["bandDescription"] as! String, snake_case["description"] as! String)
        XCTAssertEqual(camelCase["bandDescription"] as! String, snake_case_roundtrip["description"] as! String)
        XCTAssertEqual(camelCase["otherNames"] as! String, snake_case["other_names"] as! String)
        XCTAssertEqual(camelCase["otherNames"] as! String, snake_case_roundtrip["other_names"] as! String)
    }
    
    
    func testJSONGeneration() {
        
        struct BandInfo: JSONifiable {
            var name: String
            var bandDescription: String
            var formed: Int
            var disbanded: Int?
            var hiatus: Int?
            var otherNames: String?
        }
        
        let u2Dictionary = BandInfo(name: "U2", bandDescription: "Dublin boys", formed: 1976, disbanded: nil, hiatus: nil, otherNames: "Passengers").toJSONDictionary()
        XCTAssert(JSONSerialization.isValidJSONObject(u2Dictionary))
        XCTAssertEqual(u2Dictionary["name"] as! String, "U2")
        XCTAssertEqual(u2Dictionary["description"] as! String, "Dublin boys")
        XCTAssertEqual(u2Dictionary["formed"] as! Int, 1976)
        XCTAssertEqual(u2Dictionary["other_names"] as! String, "Passengers")
        
        let jsonFromManagedObjectExpectation = self.expectation(description: "JSON dictionary from NSManagedObject")
        
        DataCache.bootstrap(withModelName: "DataCacheTests", inMemory: inMemory, bundle: bundle) { (result) in
            
            switch result {
            case .success:
                self.loadJSONTestData { (result) in
                    
                    switch result {
                    case .success:
                        switch DataCache.fetchObject(ofType: "Album", withId: "Rain Tree Crow") {
                        case .success(let rainTreeCrow):
                            XCTAssertNotNil(rainTreeCrow)
                            
                            let rainTreeCrowDictionary = rainTreeCrow!.toJSONDictionary()
                            XCTAssert(JSONSerialization.isValidJSONObject(rainTreeCrowDictionary))
                            XCTAssertEqual(rainTreeCrowDictionary["name"] as! String, "Rain Tree Crow")
                            XCTAssertEqual(rainTreeCrowDictionary["band"] as! String, "Japan")
                            XCTAssertEqual(rainTreeCrowDictionary["released"] as! String, "1991-04-08T00:00:00Z")
                            XCTAssertEqual(rainTreeCrowDictionary["label"] as! String, "Virgin")
                            XCTAssertEqual(rainTreeCrowDictionary["released_as"] as! String, "Rain Tree Crow")
                            
                            jsonFromManagedObjectExpectation.fulfill()
                        case .failure(let error):
                            XCTFail("Fetching 'Stranded' failed with error: \(error)")
                        }
                    case .failure(let error):
                        XCTFail("Loading JSON failed with error: \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Bootstrap failed with error: \(error)")
            }
        }
        
        self.waitForExpectations(timeout: 5.0)
    }
    
    
    func testJSONLoading() {
        
        let expectation = self.expectation(description: "JSON loading")
        
        DataCache.bootstrap(withModelName: "DataCacheTests", inMemory: inMemory, bundle: bundle) { (result) in
            
            switch result {
            case .success:
                self.loadJSONTestData { (result) in
                    
                    switch result {
                    case .success:
                        switch DataCache.fetchObject(ofType: "Band", withId: "Roxy Music") {
                        case .success(let roxyMusic):
                            XCTAssertNotNil(roxyMusic)
                            XCTAssertEqual((roxyMusic as! Band).formed, 1971)
                            XCTAssertEqual((roxyMusic as! Band).members!.count, 7)
                            XCTAssertEqual((roxyMusic as! Band).albums!.count, 10)
                            
                            expectation.fulfill()
                        case .failure(let error):
                            XCTFail("Fetching 'Roxy Music' failed with error: \(error)")
                        }
                    case .failure(let error):
                        XCTFail("Loading JSON failed with error: \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Bootstrap failed with error: \(error)")
            }
        }
        
        self.waitForExpectations(timeout: 5.0)
    }
    
    
    func testJSONMerging() {
        
        let expectation = self.expectation(description: "JSON merging")
        
        DataCache.bootstrap(withModelName: "DataCacheTests", inMemory: inMemory, bundle: bundle) { (result: Result) in
            
            switch result {
            case .success:
                self.loadJSONTestData { (result) in
                    
                    switch result {
                    case .success:
                        switch DataCache.fetchObject(ofType: "Band", withId: "Japan") {
                        case .success(let japan):
                            XCTAssertEqual((japan as! Band).name!, "Japan")
                            XCTAssertEqual((japan as! Band).albums!.count, 7)
                            
                            let newAlbum = ["name": "Assemblage", "band": "Japan", "released": "1981-09-01T00:00:00Z", "label": "Hansa"]
                            
                            DataCache.stageChanges(withDictionary: newAlbum, forEntityWithName: "Album")
                            DataCache.applyChanges { (result) in
                                
                                switch result {
                                case .success:
                                    switch DataCache.fetchObject(ofType: "Album", withId: "Assemblage") {
                                    case .success(let assemblage):
                                        XCTAssertNotNil(assemblage)
                                        XCTAssertEqual((assemblage as! Album).name, "Assemblage")
                                        XCTAssertEqual((assemblage as! Album).band!.name, "Japan")
                                        XCTAssertEqual((japan as! Band).albums!.count, 8)
                                        
                                        expectation.fulfill()
                                    case .failure(let error):
                                        XCTFail("Fetching 'Assemblage' failed with error \(error)")
                                    }
                                case .failure(let error):
                                    XCTFail("Loading 'Assemblage' JSON failed with error: \(error)")
                                }
                            }
                        case .failure(let error):
                            XCTFail("Fetching 'Japan' failed with error \(error)")
                        }
                    case .failure(let error):
                        XCTFail("Loading JSON failed with error: \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Bootstrap failed with error: \(error)")
            }
        }
        
        self.waitForExpectations(timeout: 5.0)
    }
    
    
    func testFetchConvenienceMethods() {
        
        let fetchSingleObjectExpectation = self.expectation(description: "Fetch single object by id")
        let fetchMultipleObjectsExpectation = self.expectation(description: "Fetch multiple objects by id")
        
        DataCache.bootstrap(withModelName: "DataCacheTests", inMemory: inMemory, bundle: bundle) { (result) in
            
            switch result {
            case .success:
                self.loadJSONTestData { (result) in
                    
                    switch result {
                    case .success:
                        switch DataCache.fetchObject(ofType: "Album", withId: "Stranded") {
                        case .success(let stranded):
                            let stranded = stranded as! Album
                            XCTAssertEqual(stranded.name!, "Stranded")
                            XCTAssertEqual(stranded.band!.name!, "Roxy Music")
                            XCTAssertEqual(stranded.released as! Date, Date(fromJSONValue: "1973-11-01T00:00:00Z"))
                            XCTAssertEqual(stranded.label!, "Island")
                            
                            fetchSingleObjectExpectation.fulfill()
                        case .failure(let error):
                            XCTFail("Fetching 'Stranded' failed with error: \(error)")
                        }
                        
                        switch DataCache.fetchObjects(ofType: "Musician", withIds: ["Bryan Ferry", "Brian Eno", "David Sylvian", "Mick Karn", "Phil Manzanera", "Steve Jansen"]) {
                        case .success(let musicians):
                            XCTAssert(musicians.filter({ ($0 as! Musician).name == "Bryan Ferry" }).count == 1)
                            XCTAssert(musicians.filter({ ($0 as! Musician).name == "Brian Eno" }).count == 1)
                            XCTAssert(musicians.filter({ ($0 as! Musician).name == "David Sylvian" }).count == 1)
                            XCTAssert(musicians.filter({ ($0 as! Musician).name == "Mick Karn" }).count == 1)
                            XCTAssert(musicians.filter({ ($0 as! Musician).name == "Phil Manzanera" }).count == 1)
                            XCTAssert(musicians.filter({ ($0 as! Musician).name == "Steve Jansen" }).count == 1)
                            
                            fetchMultipleObjectsExpectation.fulfill()
                        case .failure(let error):
                            XCTFail("Fetching musicians failed with error: \(error)")
                        }
                    case .failure(let error):
                        XCTFail("Loading JSON failed with error: \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Bootstrap failed with error: \(error)")
            }
        }
        
        self.waitForExpectations(timeout: 5.0)
    }
    
    
    func testFailureScenarios() {
        
        let modelNotFoundExpectation = self.expectation(description: "Model file does not exist")
        
        DataCache.bootstrap(withModelName: "NoModel", inMemory: inMemory, bundle: bundle) { (result) in
            
            switch result {
            case .success:
                XCTFail("Bootstrapping non-existent model succeeded. This should not happen.")
            case .failure(let error):
                switch error as! DataCacheError {
                case .modelNotFound:
                    modelNotFoundExpectation.fulfill()
                    
                    DataCache.bootstrap(withModelName: "DataCacheTests", inMemory: self.inMemory, bundle: self.bundle){ (result) in
                        
                        switch result {
                        case .success:
                            
                            let objectNotFoundExpectation = self.expectation(description: "Object does not exist")
                            switch DataCache.fetchObject(ofType: "Band", withId: "U2") {
                            case .success(let band):
                                XCTAssertNil(band)
                                objectNotFoundExpectation.fulfill()
                            case .failure(let error):
                                XCTFail("Unexpected error: \(error)")
                            }
                            
                            let noSuchEntityExpectation = self.expectation(description: "Entity does not exist")
                            switch DataCache.fetchObject(ofType: "Artist", withId: "Bryan Ferry") {
                            case .success:
                                XCTFail("Fetching object with non-existent entity succeeded. This should not happen.")
                            case .failure(let error):
                                switch error as! DataCacheError {
                                case .noSuchEntity:
                                    noSuchEntityExpectation.fulfill()
                                default:
                                    XCTFail("Unexpected error: \(error)")
                                }
                            }
                        case .failure(let error):
                            XCTFail("Unexpected error: \(error)")
                        }
                    }
                default:
                    XCTFail("Unexpected error: \(error)")
                }
            }
        }
        
        self.waitForExpectations(timeout: 5.0)
    }
    
    
    // MARK: - Shared methods
    
    func loadJSONTestData(completion: @escaping (_ result: Result<Void>) -> Void) {
        
        DataCache.stageChanges(withDictionaries: self.bands, forEntityWithName: "Band")
        DataCache.stageChanges(withDictionaries: self.musicians, forEntityWithName: "Musician")
        DataCache.stageChanges(withDictionaries: self.bandMembers, forEntityWithName: "BandMember")
        DataCache.stageChanges(withDictionaries: self.albums, forEntityWithName: "Album")
        DataCache.applyChanges { (result) in
            
            switch result {
            case .success:
                DispatchQueue.main.async { completion(Result.success()) }
            case .failure(let error):
                DispatchQueue.main.async { completion(Result.failure(error)) }
            }
        }
    }
}
