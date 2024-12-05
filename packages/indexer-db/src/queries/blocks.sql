/* @name GetBlocksByRange */
SELECT *
FROM blocks
WHERE block_number BETWEEN :fromBlock AND :toBlock
ORDER BY block_number;

/* @name GetLatestBlock */
SELECT *
FROM blocks
ORDER BY block_number DESC
LIMIT 1; 