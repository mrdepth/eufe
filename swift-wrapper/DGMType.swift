//
//  DGMType.swift
//  dgmpp
//
//  Created by Artem Shimanski on 14.12.2017.
//

import Foundation
import cwrapper
import Combine

public class DGMType: DGMObject, ObservableObject {
	
	public enum MetaGroup: Int, Codable {
		case none
		case techI
		case techII
		case storyline
		case faction
		case officer
		case deadspace
		case frigates
		case eliteFrigates
		case commanderFrigates
		case destroyer
		case cruiser
		case eliteCruiser
		case commanderCruiser
		case techIII
	}
	
	class func type(_ handle: dgmpp_type) -> DGMType {
        DGMObject.get(handle) {
            switch dgmpp_get_type(handle) {
            case DGMPP_TYPE_GANG:
                return DGMGang(handle)
            case DGMPP_TYPE_CHARACTER:
                return DGMCharacter(handle)
            case DGMPP_TYPE_SKILL:
                return DGMSkill(handle)
            case DGMPP_TYPE_BOOSTER:
                return DGMBooster(handle)
            case DGMPP_TYPE_IMPLANT:
                return DGMImplant(handle)
            case DGMPP_TYPE_SHIP:
                return DGMShip(handle)
            case DGMPP_TYPE_STRUCTURE:
                return DGMStructure(handle)
            case DGMPP_TYPE_MODULE:
                return DGMModule(handle)
            case DGMPP_TYPE_DRONE:
                return DGMDrone(handle)
            case DGMPP_TYPE_CHARGE:
                return DGMCharge(handle)
			case DGMPP_TYPE_AREA:
				return DGMArea(handle)
            case DGMPP_TYPE_CARGO:
                return DGMCargo(handle)
            default:
                return DGMType(handle)
            }
        }
	}
	
	public var typeID: DGMTypeID {
		return DGMTypeID(dgmpp_type_get_type_id(handle))
	}
	
	public var groupID: DGMGroupID {
		return DGMGroupID(dgmpp_type_get_group_id(handle))
	}

	public var categoryID: DGMCategoryID {
		return DGMCategoryID(dgmpp_type_get_category_id(handle))
	}
	
	public var metaGroup: MetaGroup {
		return MetaGroup(dgmpp_type_get_meta_group(handle)) ?? .none
	}
	
	public var metaLevel: Int {
		return dgmpp_type_get_meta_level(handle)
	}

	public var parent: DGMType? {
        dgmpp_type_copy_parent(handle).map{DGMType.type($0)}
    }
	
	public subscript(attributeID: DGMAttributeID) -> DGMAttribute? {
        dgmpp_type_get_attribute(handle, dgmpp_attribute_id(attributeID)).map{DGMAttribute($0)}
	}
	
	public var affectors: [DGMType] {
		return DGMArray<DGMType>(dgmpp_type_copy_affectors(handle)).array
	}
	
	public var attributes: [DGMAttribute] {
		return DGMArray<DGMAttribute>(dgmpp_type_copy_attributes(handle)).array
	}
	
	public var identifier: Int {
		get {
			return dgmpp_type_get_identifier(handle)
		}
		set {
            willChange()
			dgmpp_type_set_identifier(handle, newValue)
		}
	}
    
    public var objectWillChange = ObservableObjectPublisher()

    func willChange() {
        if let parent = parent {
            parent.willChange()
        }
        else {
            sendChange()
        }
    }
    
    func sendChange() {
        objectWillChange.send()
    }
}
