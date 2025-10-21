-- SEE ENTIRE DATA

SELECT * FROM NashvilleHousingProject..Sheet1$;

------------------------------------------------------------------------------------

-- STANDARDIZE DATE FORMAT

SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM NashvilleHousingProject..Sheet1$;

/*
-- Create a new column temporarily
ALTER TABLE dbo.Sheet1$
ADD SaleDateClean DATE;

-- Populate it
UPDATE dbo.Sheet1$
SET SaleDateClean = CONVERT(DATE, SaleDate);

-- Drop the old column (removes it from data source, use with caution!!)
ALTER TABLE dbo.Sheet1$
DROP COLUMN SaleDate;

-- Rename the clean column
EXEC sp_rename 'dbo.Sheet1$.SaleDateClean', 'SaleDate', 'COLUMN';
*/

------------------------------------------------------------------------------------

-- REMOVE NULL VALUES IN PropertyAddress
-- AND POPULATE IT WITH AN ADDRESS THAT
-- HAS THE SAME ParcelID BUT HAS A PropertyAddress

SELECT * FROM dbo.Sheet1$
WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

SELECT
	a.ParcelID,
	a.PropertyAddress,
	b.ParcelID,
	b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.Sheet1$ a
JOIN dbo.Sheet1$ b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.Sheet1$ a
JOIN dbo.Sheet1$ b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

------------------------------------------------------------------------------------

-- SPLITTING THE PropertyAddress INTO (Address, City)

SELECT PropertyAddress FROM dbo.Sheet1$;

SELECT
PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM dbo.Sheet1$;

/*
-- Create a new column temporarily
ALTER TABLE dbo.Sheet1$
ADD Address NVARCHAR(255);

-- Populate it
UPDATE dbo.Sheet1$
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

-- Create a new column temporarily
ALTER TABLE dbo.Sheet1$
ADD City NVARCHAR(255);

-- Populate it
UPDATE dbo.Sheet1$
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Rename the columns
EXEC sp_rename 'dbo.Sheet1$.Address', 'PropertySplitAddress', 'COLUMN';
EXEC sp_rename 'dbo.Sheet1$.City', 'PropertySplitCity', 'COLUMN';
*/

SELECT * FROM dbo.Sheet1$;

------------------------------------------------------------------------------------

-- SPLITTING THE OwnerAddress INTO (Address, City, State)

SELECT OwnerAddress FROM dbo.Sheet1$;

-- PARSENAME starts from the back
SELECT OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM dbo.Sheet1$;

/*
-- Create a new column temporarily
-- Populate it
ALTER TABLE dbo.Sheet1$
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE dbo.Sheet1$
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

-- Create a new column temporarily
-- Populate it
ALTER TABLE dbo.Sheet1$
ADD OwnerSplitCity NVARCHAR(255);

UPDATE dbo.Sheet1$
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

-- Create a new column temporarily
-- Populate it
ALTER TABLE dbo.Sheet1$
ADD OwnerSplitState NVARCHAR(255);

UPDATE dbo.Sheet1$
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);
*/

SELECT * FROM dbo.Sheet1$;

------------------------------------------------------------------------------------

-- CHANGE 'Y' AND 'N' TO 'Yes' AND 'No'

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) FROM dbo.Sheet1$
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM dbo.Sheet1$
WHERE SoldAsVacant = 'Y' OR SoldAsVacant = 'N';

UPDATE dbo.Sheet1$
SET SoldAsVacant = 	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END;

------------------------------------------------------------------------------------

-- REMOVE DUPLICATES !Use with CAUTION

SELECT * FROM dbo.Sheet1$;

-- Using CTE
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM dbo.Sheet1$
)
SELECT * FROM RowNumCTE -- CHANGE SELECT * TO DELETE
WHERE row_num > 1
ORDER BY PropertyAddress;

------------------------------------------------------------------------------------

-- DELETE UNUSED COLUMNS

SELECT * FROM dbo.Sheet1$;

--ALTER TABLE dbo.Sheet1$
--DROP COLUMN PropertyAddress, TaxDistrict, OwnerAddress;
