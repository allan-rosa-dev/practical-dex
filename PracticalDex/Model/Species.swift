//
//  Species.swift
//  PracticalDex
//
//  Created by Allan Rosa on 26/07/20.
//  Copyright © 2020 Allan Rosa. All rights reserved.
//
//  This class represents a whole pokemon species, such as Wormadam, which includes all forms of Wormadam

import UIKit

/// Represents a pokemon species, which represents all pokémon that share a given name. eg: Wormadam, which includes Wormadam-Sandy, Wormadam-Trash, Wormadam-Planty. 
struct Species {
	
	// MARK: -- PROPERTIES --
	let number: Int
	let name: String
	let genderRate: Double? // percentage value, nil = genderless
	let flavorTextEntries: [Language : FlavorTextEntry]
	let genera: [Language : Genus]
	
	//	let baseHappiness: Int
	//	let captureRate: Int
	//	let color: UIColor
	let eggGroups: [EggGroup]
	//	let generation: Generation
	//	let growthRate: String // https://pokeapi.co/api/v2/growth-rate/
	//	let hasGenderDifferences: Bool
	//	let hatchCounter: Int
	//	let isBaby: Bool
	//	let names: [LocalizedName]
	
	
	// MARK: -- INIT --
	/// Placeholder init
	init() {
		number = 0
		name = ""
		genderRate = nil
		flavorTextEntries = [:]
		genera = [:]
		
		//		baseHappiness = 0
		//		captureRate = 0
		//		color = .white
		eggGroups = []
		//		generation = .i
		//		growthRate = ""
		//		hasGenderDifferences = false
		//		hatchCounter = 0
		//		isBaby = false
		//		names = []
	}
	
	/// Initialize from PokeAPI data (Parsed JSON Object)
	init(withData speciesData: PokemonSpeciesData) {
		number = speciesData.id
		name = speciesData.name
		
		// PokeAPI stores Male to Female ratio in octaves
		if speciesData.gender_rate < 0 || speciesData.gender_rate > 8 {
			genderRate = nil // Genderless (e.g., Ditto, Mew)
		} else {
			genderRate = 1 - Double(speciesData.gender_rate) / 8.0
		}
		
		var newGenera: [Language:Genus] = [:]
		speciesData.genera.forEach({ (element) in
			// TODO: Handle Nil coalescing
			let lang = Language(rawValue: element.language.name) ?? .en
			let newGenus = Genus(genusDescription: element.genus, language: lang)
			
			newGenera[lang] = newGenus
		})
		genera = newGenera
		
		var newTextEntries: [Language:FlavorTextEntry] = [:]
		speciesData.flavor_text_entries.forEach { (element) in
			// TODO: Handle Nil coalescing
			let lang = Language(rawValue: element.language.name) ?? .en
			let gameVer = GameVersion(rawValue: element.version.name) ?? .red
			let text = element.flavor_text.components(separatedBy: .whitespacesAndNewlines).joined(separator: " ")
			let newTextEntry = FlavorTextEntry(flavorTextDescription: text, language: lang, version: gameVer)
			
			newTextEntries[lang] = newTextEntry
		}
		flavorTextEntries = newTextEntries
		
		var newEggGroups: [EggGroup] = []
		speciesData.egg_groups.forEach { (element) in
			let name = element.name
			let eggGroup = EggGroup(name)
			//print("\(speciesData.name) -> \(name) \(eggGroup)")
			newEggGroups.append(eggGroup)
		}
		eggGroups = newEggGroups
	}
}

// MARK: -- PROTOCOLS --
extension Species: Persistable {
	/// Create a Species struct from a given Realm Object
	public init(managedObject: SpeciesObject) {
		number = managedObject.number
		name = managedObject.name
		genderRate = managedObject.genderRate
		
		var newGenera: [Language : Genus] = [:]
		let retrievedGenera = managedObject.generaAsArray
		retrievedGenera.forEach { (genus) in
			newGenera[genus.language] = genus
		}
		genera = newGenera
		
		var newTextEntries: [Language : FlavorTextEntry] = [:]
		let retrievedTextEntries = managedObject.flavorTextAsArray
		retrievedTextEntries.forEach { (textEntry) in
			newTextEntries[textEntry.language] = textEntry
		}
		flavorTextEntries = newTextEntries
		
		// Extra steps required to convert Strings stored in database to Enum
		let groups: [String] = managedObject.eggGroups.toArray()
		var newGroup: [EggGroup] = []
		groups.forEach({
			let newEggGroup = EggGroup($0)
			newGroup.append(newEggGroup)
		})
		eggGroups = newGroup
		
		//		baseHappiness = managedObject.baseHappiness
		//		captureRate = managedObject.captureRate
		//		color = UIColor.black
		//		generation = .i
		//		generation = managedObject.generation
		
		//		growthRate = managedObject.growthRate
		//		hasGenderDifferences = managedObject.hasGenderDifferences
		//		hatchCounter = managedObject.hatchCounter
		//		isBaby = managedObject.isBaby
		//
		//		names = []
		//		names = managedObject.names
	}
	
	func managedObject() -> SpeciesObject {
		let speciesObject = SpeciesObject()
		
		speciesObject.number = number
		speciesObject.name = name
		speciesObject.genderRate = genderRate ?? -1
		
		self.genera.forEach { (lang, genus) in
			let newGenus = GenusObject()
			newGenus.genusDescription = genus.genusDescription
			newGenus.language = lang.rawValue
			
			speciesObject.genera.append(newGenus)
		}
		
		self.flavorTextEntries.forEach { (lang, textEntry) in
			let newTextEntry = FlavorTextEntryObject()
			newTextEntry.flavorTextDescription = textEntry.flavorTextDescription
			newTextEntry.language = lang.rawValue
			newTextEntry.version = textEntry.version.rawValue
			
			speciesObject.flavorTextEntries.append(newTextEntry)
		}
		
		self.eggGroups.forEach { (eggGroup) in
			speciesObject.eggGroups.append(eggGroup.description.lowercased().trimmingCharacters(in: .whitespaces))
		}
		
		return speciesObject
	}
}

