# Cleaning of Nashville Housing Data in SQL

The goal of this project was to extract publicly accessible data, and load it into SQL for cleaning.

The data accessed was publicly provided housing data from the Nashville Metropolitan Area.

- Duplicates were removed as best seen fit
- Addresses were broken up into city, state, and street address
- Values were replaced to use terms that would benefit later data analysis and visualization
- NULL values were either filled or removed as needed using CTE:
```
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
```
