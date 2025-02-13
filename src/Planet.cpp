//
//  Planet.cpp
//  dgmpp
//
//  Created by Artem Shimanski on 28.11.2017.
//

#include "Planet.hpp"
#include "SDE.hpp"
#include "CommandCenter.hpp"
#include "Factory.hpp"
#include "Spaceport.hpp"
#include "ExtractorControlUnit.hpp"

#include <algorithm>

namespace dgmpp {
	std::shared_ptr<Facility> Planet::add(TypeID typeID, Facility::Identifier identifier) {
		const auto& metaInfo = SDE::facility(typeID);
        std::shared_ptr<Facility> facility;
		
		if (identifier <= 0)
			identifier = facilities_.size() + 1;
		
		switch (metaInfo.groupID) {
			case GroupID::commandCenters:
				facility.reset(new CommandCenter(metaInfo, *this, identifier));
				break;
			case GroupID::processors:
				facility.reset(new Factory(metaInfo, *this, identifier));
				break;
			case GroupID::storageFacilities:
				facility.reset(new Storage(metaInfo, *this, identifier));
				break;
			case GroupID::spaceports:
				facility.reset(new Spaceport(metaInfo, *this, identifier));
				break;
			case GroupID::extractorControlUnits:
				facility.reset(new ExtractorControlUnit(metaInfo, *this, identifier));
				break;
			default:
				break;
		}
		assert(facility);
		
		facilities_.push_back(facility);
		return facility;
	}
	
	void Planet::remove(Facility* facility) {
		for (auto& route: facility->inputs_)
			route.from->outputs_.erase(route);
		for (auto& route: facility->outputs_)
			route.to->inputs_.erase(route);
		
		auto i = std::find_if(facilities_.begin(), facilities_.end(), [&](const auto& i) { return i.get() == facility; });
//		auto i = facilities_.find(facility);
		assert(i != facilities_.end());
		facilities_.erase(i);
	}
	
	const std::list<std::shared_ptr<Facility>>& Planet::facilities() const {
        return facilities_;
	}
	
	std::shared_ptr<Facility> Planet::operator[] (Facility::Identifier key) const {
		auto i = std::find_if(facilities_.begin(), facilities_.end(), [key](const auto& i) { return i->identifier() == key; });
		return i != facilities_.end() ? *i : nullptr;
	}

	void Planet::add(const Route& route) {
		if (!route.from || !route.to)
			throw InvalidRoute();
		route.from->outputs_.insert(route);
		route.to->inputs_.insert(route);
	}
	
	void Planet::remove(const Route& route) {
		route.from->outputs_.erase(route);
		route.to->inputs_.erase(route);
	}
	
	std::optional<std::chrono::seconds> Planet::nextCycleTime_(const std::set<Facility*, FacilityCompare>& facilities) const noexcept {
		std::optional<std::chrono::seconds> next = std::nullopt;
		for (auto& facility: facilities) {
			if (auto time = facility->nextUpdateTime_(); time && *time >= timestamp_)
				next = next ? std::min(*next, *time) : time;
		}
		return next;
	}
	
	std::chrono::seconds Planet::run() {
		auto endTime = std::chrono::seconds::zero();
		timestamp_ = endTime;

		std::set<Facility*, FacilityCompare> facilities;
		for (const auto& i: facilities_) {
			if (i->configured()) {
				facilities.insert(i.get());
			}
		}
		
		while(true) {
			if (auto next = nextCycleTime_(facilities); next && next->count() >= 0) {
				timestamp_ = *next;
				for (auto& i: facilities)
					i->update_(timestamp_);
				endTime = *next;
			}
			else
				break;
		}
		
		return endTime;
	}

}
