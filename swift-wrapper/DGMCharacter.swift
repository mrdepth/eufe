//
//  DGMCharacter.swift
//  dgmpp
//
//  Created by Artem Shimanski on 14.12.2017.
//

import Foundation
import cwrapper

public class DGMImplant: DGMType, Codable {
	
    required init(_ handle: dgmpp_type) {
        super.init(handle)
    }

	public convenience init(typeID: DGMTypeID) throws {
		guard let type = dgmpp_implant_create(dgmpp_type_id(typeID)) else { throw DGMError.typeNotFound(typeID)}
		self.init(type)
	}

	public convenience init(_ other: DGMImplant) {
		self.init(dgmpp_implant_copy(other.handle))
	}

	public var slot: Int {
		return Int(dgmpp_implant_get_slot(handle))
	}
	
	public convenience required init(from decoder: Decoder) throws {
		let typeID = try decoder.container(keyedBy: CodingKeys.self).decode(DGMTypeID.self, forKey: .typeID)
		try self.init(typeID: typeID)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(typeID, forKey: .typeID)
	}
	
	enum CodingKeys: String, CodingKey {
		case typeID
	}
}

public class DGMBooster: DGMType, Codable {
	
    required init(_ handle: dgmpp_type) {
        super.init(handle)
    }

	public convenience init(typeID: DGMTypeID) throws {
		guard let type = dgmpp_booster_create(dgmpp_type_id(typeID)) else { throw DGMError.typeNotFound(typeID)}
		self.init(type)
	}

	public convenience init(_ other: DGMBooster) {
		self.init(dgmpp_booster_copy(other.handle))
	}

	public var slot: Int {
		return Int(dgmpp_booster_get_slot(handle))
	}
	
	public convenience required init(from decoder: Decoder) throws {
		let typeID = try decoder.container(keyedBy: CodingKeys.self).decode(DGMTypeID.self, forKey: .typeID)
		try self.init(typeID: typeID)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(typeID, forKey: .typeID)
	}
	
	enum CodingKeys: String, CodingKey {
		case typeID
	}
}

public class DGMSkill: DGMType {
	
	public var level: Int {
		get {
			return Int(dgmpp_skill_get_level(handle))
		}
		set {
            willChange()
			dgmpp_skill_set_level(handle, Int32(newValue))
		}
	}
	
    fileprivate func setLevelWithoutUpdates(_ level: Int) {
        dgmpp_skill_set_level(handle, Int32(level))
    }
}

public class DGMCharacter: DGMType, Codable {
    
    required init(_ handle: dgmpp_type) {
        super.init(handle)
    }
	
	public convenience init() throws {
		self.init(dgmpp_character_create()!)
	}

	public convenience init(_ other: DGMCharacter) {
		self.init(dgmpp_character_copy(other.handle)!)
	}

	public var name: String {
		get {
			return String(cString: dgmpp_character_get_name(handle));
		}
		set {
			guard let string = newValue.cString(using: .utf8) else {return}
            willChange()
			dgmpp_character_set_name(handle, string)
		}
	}

	
	public var ship: DGMShip? {
		get {
			guard let ship = dgmpp_character_copy_ship(handle) else {return nil}
            return DGMType.type(ship) as? DGMShip
		}
		set {
            willChange()
			dgmpp_character_set_ship(handle, newValue?.handle)
		}
	}
	
//	public var structure: DGMStructure? {
//		get {
//			guard let structure = dgmpp_character_get_structure(handle) else {return nil}
//			return DGMStructure(structure)
//		}
//		set {
//			dgmpp_character_set_structure(handle, newValue?.handle)
//		}
//	}
	
	public func setSkillLevels(_ level: Int) {
        willChange()
		dgmpp_character_set_skill_levels(handle, Int32(level))
	}
    
    public func setSkillLevels(_ levels: [DGMTypeID: Int]) {
        willChange()
        let skills = Dictionary(self.skills.map{($0.typeID, $0)}) {a, _ in a}
        for (typeID, level) in levels {
            skills[typeID]?.setLevelWithoutUpdates(level)
        }
    }
	
	public func add(_ implant: DGMImplant, replace: Bool = false) throws {
        willChange()
		guard dgmpp_character_add_implant(handle, implant.handle, replace ? 1 : 0) != 0 else { throw DGMError.cannotFit(implant)}
	}
	
	public func add(_ booster: DGMBooster, replace: Bool = false) throws {
        willChange()
		guard dgmpp_character_add_booster(handle, booster.handle, replace ? 1 : 0) != 0 else { throw DGMError.cannotFit(booster)}
	}
	
	public func remove(_ implant: DGMImplant) {
        willChange()
		dgmpp_character_remove_implant(handle, implant.handle)
	}

	public func remove(_ booster: DGMBooster) {
        willChange()
		dgmpp_character_remove_booster(handle, booster.handle)
	}
	
	public var implants: [DGMImplant] {
		return DGMArray<DGMImplant>(dgmpp_character_copy_implants(handle)).array
	}

	public var boosters: [DGMBooster] {
		return DGMArray<DGMBooster>(dgmpp_character_copy_boosters(handle)).array
	}

	public var skills: [DGMSkill] {
		return DGMArray<DGMSkill>(dgmpp_character_copy_skills(handle)).array
	}
	
	public var droneControlDistance: DGMMeter {
		return dgmpp_character_get_drone_control_distance(handle)
	}

	public convenience required init(from decoder: Decoder) throws {
		try self.init()

		let container = try decoder.container(keyedBy: CodingKeys.self)
		try container.decode([DGMImplant].self, forKey: .implants).forEach { try add($0) }
		try container.decode([DGMBooster].self, forKey: .boosters).forEach { try add($0) }
        name = try container.decode(String.self, forKey: .name)
        
        let data = try container.decode(Data.self, forKey: .skills)
        let skills = self.skills
        let n = skills.count
        let last = n - 1

        data.withUnsafeBytes { buffer in
            let ptr = buffer.bindMemory(to: UInt8.self)
            for i in stride(from: 0, to: n, by: 2) {
                let j = i >> 1
                guard j < ptr.count else {continue}
                let l = ptr[j]
                skills[i].level = Int(l >> 4)
                if i < last {
                    skills[i + 1].level = Int(l & 0xf)
                }
            }
        }
        
		ship = try container.decodeIfPresent(DGMShip.self, forKey: .ship)
		if let identifier = try container.decodeIfPresent(Int.self, forKey: .identifier) {
			self.identifier = identifier
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(implants, forKey: .implants)
		try container.encode(boosters, forKey: .boosters)
		try container.encodeIfPresent(ship, forKey: .ship)
		try container.encode(identifier, forKey: .identifier)
        try container.encode(name, forKey: .name)
        
        let skills = self.skills
        let n = skills.count
        let last = n - 1
        var data = Data(count: n / 2 + n % 2)
        data.withUnsafeMutableBytes { buffer in
            let ptr = buffer.bindMemory(to: UInt8.self)
            for i in stride(from: 0, to: n, by: 2) {
                ptr[i >> 1] = UInt8((skills[i].level << 4) + (i < last ? skills[i + 1].level : 0))
            }
        }
        try container.encode(data, forKey: .skills)
	}
	
	enum CodingKeys: String, CodingKey {
		case implants
		case boosters
		case ship
		case identifier
        case skills
        case name
	}
    
    override func sendChange() {
        super.sendChange()
        ship?.sendChange()
    }
}
