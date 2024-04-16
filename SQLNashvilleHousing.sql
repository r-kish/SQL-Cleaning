-- Nashville Metropolitan Area Housing SQL Data Cleaning Project
-- by: Richard Kish
-- Completed 1/30/2024
-- Please use with NashvilleHousing.xlsx
------------------------------------------------------------------------------------------------------------

-- View the entire dataset
Select *
From NashvilleHousing.dbo.NashvilleHousing

------------------------------------------------------------------------------------------------------------

-- CLEAN DATE FORMAT
-- Solution 1
ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
ALTER COLUMN SaleDate Date

UPDATE NashvilleHousing.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

-- Solution 2
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM NashvilleHousing.dbo.NashvilleHousing

------------------------------------------------------------------------------------------------------------

-- POPULATE NULL PROPERTY ADDRESS DATA
-- Verification that ParcelIDs match PropertyAddress for multiple entries
SELECT *
FROM NashvilleHousing.dbo.NashvilleHousing
--Where PropertyAddress is NULL
ORDER BY ParcelID

-- Will show all NULL values
SELECT one.ParcelID, one.PropertyAddress, two.ParcelID, two.PropertyAddress, ISNULL(one.PropertyAddress, two.PropertyAddress)
FROM NashvilleHousing.dbo.NashvilleHousing one
JOIN NashvilleHousing.dbo.NashvilleHousing two
	ON one.ParcelID = two.ParcelID
	AND one.[UniqueID ] <> two.[UniqueID ]
WHERE one.PropertyAddress IS NULL

-- Populate NULL PropertyAddress values
UPDATE one
SET PropertyAddress = ISNULL(one.PropertyAddress, two.PropertyAddress)
FROM NashvilleHousing.dbo.NashvilleHousing one
JOIN NashvilleHousing.dbo.NashvilleHousing two
	ON one.ParcelID = two.ParcelID
	AND one.[UniqueID ] <> two.[UniqueID ]

-- Repeat from before UPDATE query; should show no NULL values now for PropertyAddress
SELECT one.ParcelID, one.PropertyAddress, two.ParcelID, two.PropertyAddress, ISNULL(one.PropertyAddress, two.PropertyAddress)
FROM NashvilleHousing.dbo.NashvilleHousing one
JOIN NashvilleHousing.dbo.NashvilleHousing two
	ON one.ParcelID = two.ParcelID
	AND one.[UniqueID ] <> two.[UniqueID ]
WHERE one.PropertyAddress IS NULL

------------------------------------------------------------------------------------------------------------

-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (Address, City, State)
-- We will be deriving Address and City columns from this selection of data
Select PropertyAddress
FROM NashvilleHousing.dbo.NashvilleHousing

-- Pull Address and City from PropertyAddress using SUBSTRING
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address
FROM NashvilleHousing.dbo.NashvilleHousing

-- Create new columns and apply pulling of address via substring to dataset
ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
ADD PropertySepAddress nvarchar(255);

ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
ADD PropertySepCity nvarchar(255);

UPDATE NashvilleHousing.dbo.NashvilleHousing
SET PropertySepAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

UPDATE NashvilleHousing.dbo.NashvilleHousing
SET PropertySepCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-- Parsing out Address, City, and State from OwnerAddress using PARSENANE
-- We will be deriving the Address, City, and State columns from this selection of data
SELECT OwnerAddress
FROM NashvilleHousing.dbo.NashvilleHousing

-- Show how address will be parsed out
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing.dbo.NashvilleHousing

-- Create new columns and apply parsing of address to dataset
ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
ADD OwnerSepAddress nvarchar(255);

ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
ADD OwnerSepCity nvarchar(255);

ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
ADD OwnerSepState nvarchar(255);

UPDATE NashvilleHousing.dbo.NashvilleHousing
SET OwnerSepAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE NashvilleHousing.dbo.NashvilleHousing
SET OwnerSepCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE NashvilleHousing.dbo.NashvilleHousing
SET OwnerSepState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

------------------------------------------------------------------------------------------------------------

-- CHANGE ALL "Y" and "N" to say "Yes" and "No" in SoldAsVacant column
-- Display how many entries are separately labeled as "Y" and "N", apart from the majority of "Yes" and "No"
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- Display all SoldAsVacant rows before and after cleaning
SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM NashvilleHousing.dbo.NashvilleHousing

-- Apply cleaning to dataset
UPDATE NashvilleHousing.dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END

------------------------------------------------------------------------------------------------------------

-- REMOVING DUPLICATES
-- Using CTE 
WITH row_numCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
	ORDER BY UniqueID
	) row_num

FROM NashvilleHousing.dbo.NashvilleHousing
)
DELETE
FROM row_numCTE
WHERE row_num > 1

------------------------------------------------------------------------------------------------------------

-- REMOVING UNUSED COLUMNS
ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate

-- VIEW FINAL CLEANED DATASET
SELECT *
FROM NashvilleHousing.dbo.NashvilleHousing
