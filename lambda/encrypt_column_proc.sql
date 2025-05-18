DROP PROCEDURE IF EXISTS encrypt_columns;
DELIMITER //
CREATE PROCEDURE encrypt_columns(
    IN in_table_name VARCHAR(64),
    IN in_column_list TEXT,
    IN encryption_key VARCHAR(64)
)
BEGIN
    DECLARE col_list TEXT;
    DECLARE done INT DEFAULT FALSE;
    DECLARE cur CURSOR FOR SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(in_column_list, ',', numbers.n), ',', -1)) AS column_name
                           FROM (SELECT units.i + tens.i * 10 + 1 AS n
                                 FROM (SELECT 0 i UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
                                       UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) units,
                                      (SELECT 0 i UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
                                       UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) tens
                                ) numbers
                           WHERE numbers.n <= 1 + LENGTH(in_column_list) - LENGTH(REPLACE(in_column_list, ',', ''));

    SET col_list = '';
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO @col;
        IF done THEN
            LEAVE read_loop;
        END IF;
        IF @col IS NOT NULL THEN
            SET col_list = CONCAT_WS(', ', col_list, CONCAT(@col, ' = TO_BASE64(AES_ENCRYPT(', @col, ', "', encryption_key, '"))'));
        END IF;
    END LOOP;
    CLOSE cur;

    SET @final_sql = CONCAT('UPDATE ', in_table_name, ' SET ', col_list);
    PREPARE stmt FROM @final_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END;
//
DELIMITER ;
