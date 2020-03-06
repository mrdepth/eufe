//
//  HeatSimulator.cpp
//  dgmpp
//
//  Created by Artem Shimanski on 07.12.2017.
//

#include "HeatSimulator.hpp"
#include "Ship.hpp"
#include <numeric>
#include <queue>
#include <functional>

#include <iostream>

namespace dgmpp {
	
	static Float heat(std::chrono::milliseconds t, Float heatCapacity, Float heatGeneration) {
		return heatCapacity - std::exp(-t.count() / 1000.0 * heatGeneration);
	}
	
	static Float damageProbability(Float h, std::size_t range, std::size_t numberOfOnlineModules, std::size_t numberOfSlots, Float heatAttenuation) {
		return static_cast<Float>(numberOfOnlineModules) / static_cast<Float>(numberOfSlots) * h * std::pow(heatAttenuation, range);
	}

	void HeatSimulator::simulate() {
		
		if (flags_.isCalculated_)
			return;
		heatGenerationMultiplier_ = owner_.attribute_(AttributeID::heatGenerationMultiplier)->value_();
		
		for (auto slot: {Module::Slot::hi, Module::Slot::med, Module::Slot::low})
			run_(slot);
		flags_.isCalculated_ = true;
	}
	
	void HeatSimulator::run_(Module::Slot slot) {
		const auto totalSlots = owner_.totalSlots_(slot);

		auto modules = owner_.modules_(slot);
		modules.erase(std::remove_if(modules.begin(), modules.end(), [totalSlots](auto i) {
			return i->socket_() >= totalSlots;
		}), modules.end());
		
		if (modules.empty())
			return;
		
		const auto onlineModules = std::count_if(modules.begin(), modules.end(), [](auto i) { return i->state_() >= Module::State::online; });
		const auto heatAbsorbtionRateModifier = std::accumulate(modules.begin(), modules.end(), Float(0), [](auto sum, auto i) {
			return i->state_() == Module::State::overloaded
			? sum + i->attribute_(AttributeID::heatAbsorbtionRateModifier)->value_()
			: sum;
		});
		const auto heatGeneration = heatAbsorbtionRateModifier * heatGenerationMultiplier_;
		
		Float heatCapacity = 0;
		Float heatAttenuation = 0;
		switch (slot) {
			case Module::Slot::hi:
				heatCapacity = owner_.attribute_(AttributeID::heatCapacityHi)->value_() / 100.0;
				heatAttenuation = owner_.attribute_(AttributeID::heatAttenuationHi)->value_();
				break;
			case Module::Slot::med:
				heatCapacity = owner_.attribute_(AttributeID::heatCapacityMed)->value_() / 100.0;
				heatAttenuation = owner_.attribute_(AttributeID::heatAttenuationMed)->value_();
				break;
			case Module::Slot::low:
				heatCapacity = owner_.attribute_(AttributeID::heatCapacityLow)->value_() / 100.0;
				heatAttenuation = owner_.attribute_(AttributeID::heatAttenuationLow)->value_();
				break;
			default:
				break;
		}
		
		std::vector<std::pair<HP, Module*>> hp(totalSlots, std::make_pair(HP(0), nullptr));

		std::vector<State> c;
		c.reserve(modules.size());

		for (auto i: modules) {
			hp[i->socket_()] = std::make_pair(i->attribute_(AttributeID::hp)->value_(), i.get());
			if (i->state_() == Module::State::overloaded) {
				c.emplace_back(i->rawCycleTime_(), i->reloadTime_(), i->attribute_(AttributeID::heatDamage)->value_(), i->shots_(), i->socket_());
			}
		}
		if (c.empty())
			return;

		typedef std::priority_queue<State, std::vector<State>, std::greater<>> PQ;
		PQ states(PQ::value_compare(), std::move(c));
		
		auto tNow = 0ms;

		while (true) {
			auto state = states.top();
			states.pop();
			tNow = state.tNow;
			
			auto h = heat(tNow, heatCapacity, heatGeneration);
			std::size_t dead = 0;
			for (int i = 0; i < totalSlots; i++) {
				if (hp[i].first > 0) {
					auto range = std::abs(i - static_cast<int>(state.socket));
					hp[i].first -= damageProbability(h, range, onlineModules, totalSlots, heatAttenuation) * state.heatDamage;
					if (hp[i].first <= 0) {
						hp[i].second->lifeTime_ (tNow);
						dead++;
					}
				}
				else
					dead++;
			}
			
			if (dead >= totalSlots)
				break;
			
			tNow += state.cycleTime;
			state.shot++;
			
			if (state.clipSize > 0) {
				if (state.shot % state.clipSize == 0) {
					state.shot = 0;
					tNow += state.reloadTime;
				}
			}
			state.tNow = tNow;
			states.push(state);
		}
	}
	
	bool HeatSimulator::factorReload_() const noexcept {
		return owner_.factorReload_();
	}
	
}
