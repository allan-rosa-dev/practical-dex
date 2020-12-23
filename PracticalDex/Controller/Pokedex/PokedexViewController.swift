//
//  PokedexViewController.swift
//  PracticalDex
//
//  Created by Allan Rosa on 13/07/20.
//  Copyright © 2020 Allan Rosa. All rights reserved.
//

import UIKit

class PokedexViewController: UIViewController {
	
	private var selectedPokemon = Pokemon()
	private var pokedexManager = PokedexManager()
	private var searchController = UISearchController()
	@IBOutlet weak var collectionView: UICollectionView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		pokedexManager.delegate = self
		collectionView.delegate = self
		collectionView.dataSource = self
		
		if let settingsNavVC = tabBarController?.viewControllers![1] as? UINavigationController {
			if let settingsVC = settingsNavVC.topViewController as? SettingsViewController {
				settingsVC.settingsDelegate = self
			}
		}
		
		//pokedexManager.populatePokedex(fromNumber: 0, toNumber: 1)
		pokedexManager.populatePokedex(fromNumber: 0, toNumber: 31)
		//pokedexManager.populatePokedex(entriesLimit: 151, offset: 0)
		//pokedexManager.populatePokedex(entriesLimit: 800, offset: 0)
		
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		collectionView.reloadData() // Updates cells to reflect changes done in settings
	}
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		let destinationVC = segue.destination as! DetailViewController
		collectionView.reloadData()
		destinationVC.pokemon = selectedPokemon
	}
	
}

// MARK: -- PROTOCOLS --
// MARK: PokedexManagerDelegate
extension PokedexViewController: PokedexManagerDelegate {
	func didFinishFetchingSpecies(_ pokedexManager: PokedexManager) {
		pokedexManager.updateFetchStatus(.Species)
		pokedexManager.spcsGroup.notify(queue: .main, execute: {
			print("DID FINISH FETCHING SPECIES")
			self.pokedexManager.persist(speciesList: true)
		})
	}
	
	func didFinishFetchingPokemon(_ pokedexManager: PokedexManager) {
		pokedexManager.updateFetchStatus(.Pokemon)
		pokedexManager.pkmnGroup.notify(queue: .main, execute: {			
			print("DID FINISH FETCHING POKEMON")
			pokedexManager.persist(pokemonList: true)
			self.collectionView.reloadData()
		})
	}
	
	func didFailWithError(_ error: Error) {
		// handle possible errors - e.g. present popups with infos regarding error and possible solutions
		// internet connection error
	}
	
	// Used to update the pokedex as each entry is added
	func didRetrievePokemon(_ pokedexManager: PokedexManager, pokemon: Pokemon) {
		// DispatchQueue is used in order to free the main thread while data is fetched, so the app isn't frozen
		DispatchQueue.main.async {
			self.collectionView.reloadData()
		}
	}
}

//MARK: - SettingsDelegate
extension PokedexViewController: SettingsDelegate {	
	func dataNeedsReloading() {
		collectionView.reloadData()
	}
	
	func resetData() {
		pokedexManager.resetData(purgeDatabase: true)
		collectionView.reloadData()
		pokedexManager.populatePokedex(fromNumber: 0, toNumber: 51)
	}
}

// MARK: CollectionView Delegate & DataSource
extension PokedexViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return pokedexManager.pokemonList.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		var cell = UICollectionViewCell()
		if let pokedexCell = collectionView.dequeueReusableCell(withReuseIdentifier: K.App.View.Cell.pokedex, for: indexPath) as? PokedexCell {
			
			// indexPath.row is zero indexed, pokémon numbers are 1 indexed
			if let cellPokemon = pokedexManager.pokemonList[indexPath.row+1] {
				pokedexCell.configure(with: cellPokemon)
			}
			cell = pokedexCell
		}
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		// indexPath.row is zero indexed, pokémon numbers are 1 indexed
		var pokemon = pokedexManager.pokemonList[indexPath.row+1]
		
		// TODO: REVIEW WHERE SHOULD THIS GO
		for species in pokedexManager.speciesList {
			if species.number == pokemon?.number {
				pokemon?.species = species
				break
			}
		}
		selectedPokemon = pokemon ?? Pokemon()
		self.performSegue(withIdentifier: K.App.View.Segue.detailView, sender: self)
	}
}

//MARK: - CollectionViewDelegateFlowLayout
extension PokedexViewController: UICollectionViewDelegateFlowLayout {
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets(top: 24, left: 6, bottom: 6, right: 6)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		
		let numberOfColumns: CGFloat = 2
		let totalWidth = view.frame.width
		let totalOffsetSpace: CGFloat = 18 // in points (min for 2 columns = 12)
		let pokedexCellWidth = (totalWidth - totalOffsetSpace) / numberOfColumns
		
		return CGSize(width: pokedexCellWidth, height: pokedexCellWidth) // make the cell a square
	}
}

//MARK: - SearchBarController & Delegate
extension PokedexViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
	func updateSearchResults(for searchController: UISearchController) {
		let searchString = "<Search>"
		print ("Search for : \(searchString) -> Updating...")
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		self.dismiss(animated: true, completion: nil)
	}
	
	func setupSearchBar(){
		// SearchBar at the top
		self.searchController = UISearchController(searchResultsController:  nil)
		
		self.searchController.searchResultsUpdater = self
		self.searchController.delegate = self
		self.searchController.searchBar.delegate = self
		
		self.searchController.hidesNavigationBarDuringPresentation = false
		//self.searchController.dimsBackgroundDuringPresentation = true
		self.searchController.obscuresBackgroundDuringPresentation = false
		
		searchController.searchBar.becomeFirstResponder()
		
		self.navigationItem.titleView = searchController.searchBar
	}
}
