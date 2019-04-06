#priority 3000

/*
	SkyFactory 4 Resource Class Script

	This script is a zenClass to store information and methods for a resource.

	handle methods handle recipes where the given part is the input of the recipe
*/
import crafttweaker.item.IItemStack;
import crafttweaker.liquid.ILiquidStack;
import crafttweaker.oredict.IOreDictEntry;

import mods.zenstages.Stage;

import scripts.crafttweaker.craftingUtils;
import scripts.crafttweaker.utils;

zenClass Resource {
	var resourceName as string;
	var parts as IItemStack[string] = {};
	var partsOredict as IOreDictEntry[string] = {};
	var liquid as ILiquidStack;
	var stage as Stage;

	zenConstructor(resourceName as string) {
		this.resourceName = resourceName;
	}

	function addPart(partName as string, partItem as IItemStack, partOredict as IOreDictEntry) {
		if (!isNull(parts[partName])) {
			logger.logError("Attempted to add " ~ partName
				~ " to Resource '" ~ resourceName ~ "' but it already exists");
			return null;
		}

		parts[partName] = partItem;
		partsOredict[partName] = partOredict;
	}

	function setLiquid(liquid as ILiquidStack) {
		if (!isNull(this.liquid)) {
			logger.logError("Attempted to add liquid to Resource '"
				~ resourceName ~ "' but it already exists");
			return null;
		}

		this.liquid = liquid;
	}

	function hasPart(partName as string) as bool {
		return (this.parts has partName) & !isNull(this.parts[partName]);
	}

	function hasLiquid() as bool {
		return !isNull(this.liquid);
	}

	function init() {
		// ==============================
		// Stage the Liquid
		if (!isNull(this.stage) & hasLiquid()) {
			this.stage.addLiquid(this.liquid);
			this.stage.addIngredient(craftingUtils.getBucketIngredient(this.liquid));
		}

		// ==============================
		// Loop over the parts for the Metal and handle each part for correcting/changing processing recipes/mechanics.
		for partName, part in this.parts {
			if (!isNull(part)) {
				if (partName == "ore") {
					var oreOreDict as IOreDictEntry = utils.getResourcePartOreDict(partName, this.resourceName);

					if (!isNull(this.stage)) {
						this.stage.addIngredient(oreOreDict);
					}

					handleOre(oreOreDict);
				} else {
					// Stage the part.
					if (!isNull(this.stage)) {
						this.stage.addIngredient(part);
					}

					addTinkersPartRecipes(partName);
				}
			}
		}

		handleDirtyDust();
		handleDust();
		handleIngot();
		handleNugget();
		handlePlate();
		handleBlock();
		handleRod();
		handleLiquid();

		createConversionRecipes();
	}

	/**
	 * Add recipes to tinkers for a given part.
	 * @param {string} partName
	 */
	function addTinkersPartRecipes(partName as string) {
		if (!hasLiquid()) {
			return null;
		}

		var part as IItemStack = this.parts[partName];
		var fluidAmount as int = utils.getFluidAmount(partName);

		// ==============================
		// Melting
		if (fluidAmount != 0) {
			tinkers.addMelting(this.liquid * fluidAmount, part);
		}

		// ==============================
		// Casting
		if (partName == "block") {
			tinkers.addCastingBasin(part, null, liquid, fluidAmount, false);
		} else {
			var tinkersCast as IItemStack = utils.getTinkersCast(partName);
			if (!isNull(tinkersCast)) {
				tinkers.addCastingTable(part, tinkersCast, liquid, fluidAmount, false);
			}
		}
	}

	function handleDirtyDust() {
		if (!hasPart("dirtyDust")) {
			return null;
		}

		if (hasPart("dust")) {
			mekanism.addEnrichment(this.parts.dirtyDust, this.parts.dust);
		}
	}

	function handleDust() {
		if (!hasPart("dust")) {
			return null;
		}

		if (hasPart("ingot")) {
			mekanism.addSmelter(this.parts.dust, this.parts.ingot);
		}

		if (hasLiquid()) {
			nuclearCraft.addMelter(this.parts.dust, this.liquid * 144);
		}
	}

	function handleIngot() {
		if (!hasPart("ingot")) {
			return null;
		}

		if (hasPart("block")) {
			recipes.addShaped(this.parts.block, craftingUtils.create3By3(this.parts.ingot));
		}

		if (hasPart("nugget")) {
			recipes.addShapeless(this.parts.nugget * 9, [this.parts.ingot]);
		}

		if (hasPart("plate")) {
			practicalLogistics.addHammer(this.parts.plate, this.parts.ingot * 2);
			nuclearCraft.addPressurizer(this.parts.plate, this.parts.ingot);
		}

		if (hasLiquid()) {
			nuclearCraft.addMelter(this.parts.ingot, this.liquid * 144);
		}

		if (hasPart("gear")) {
			recipes.addShaped(this.parts.gear, [
				[null, this.parts.ingot, null],
				[this.parts.ingot, null, this.parts.ingot],
				[null, this.parts.ingot, null]
			]);
		}
	}

	function handleNugget() {
		if (!hasPart("nugget")) {
			return null;
		}

		if (hasPart("ingot")) {
			recipes.addShaped(this.parts.ingot, craftingUtils.create3By3(this.parts.nugget));
			cyclic.addPackager(this.parts.ingot, this.parts.nugget * 9);
		}

		if (hasLiquid()) {
			nuclearCraft.addMelter(this.parts.nugget, this.liquid * 16);
		}
	}

	function handlePlate() {
		if (!hasPart("plate")) {
			return null;
		}
	}

	function handleBlock() {
		if (!hasPart("block")) {
			return null;
		}

		if (hasLiquid()) {
			nuclearCraft.addMelter(this.parts.block, this.liquid * 1296);
		}

		if (hasPart("ingot")) {
			recipes.addShapeless(this.parts.ingot * 9, [this.parts.block]);
		}
	}

	function handleRod() {
		if (!hasPart("rod")) {
			return null;
		}
	}

	function handleOre(oreOreDict as IOreDictEntry) {
		if (!hasPart("ore")) {
			return null;
		}

		for ore in oreOreDict.items {
			if (hasPart("dust")) {
				astralSorcery.addGrindstone(ore, this.parts.dust, 0.85);
				mekanism.addCrusher(ore, this.parts.dust);
			}
		}
	}

	function handleLiquid() {
		if (!hasLiquid()) {
			return null;
		}

		if (hasPart("ingot")) {
			nuclearCraft.addIngotFormer(this.liquid * 144, this.parts.ingot);
		}
	}

	/*
		This adds the processing such as Ingot -> Dust or other conversions needed for the Ore outputs which are removed
		in process with cleaning up via the `removeRecipes` Function.
	*/
	function createConversionRecipes() {
		// Handle the Ingot -> Dust conversion.
		if (hasPart("ingot") & hasPart("dust")) {
			astralSorcery.addGrindstone(this.parts.ingot, this.parts.dust);
			mekanism.addCrusher(this.parts.ingot, this.parts.dust);
			nuclearCraft.addManufactory(this.parts.ingot, this.parts.dust);
		}
	}
}