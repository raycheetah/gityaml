-- 定義包含 UUID 和 Outbound 的變數陣列
# SET @uuids = '22a5b599-04a9-440b-bcae-aa028d9e0462,53fe8cb7-ab61-42cd-82d5-809f69098566,6f685e8f-3163-41e3-951a-f920207969e8,2c34c157-c359-4082-84ae-728910e7e737,6248c0ae-0690-4dc3-9170-5ee20abab44a,85480c07-4945-4c9a-8a84-43b3325e2936,812d73a7-3737-43b9-9275-f97e56a522c2,2564bd99-a1ff-49e6-a1f3-a063e0a65187,02e64cc4-bb4a-4475-87bb-aff9731aea78,709be815-dcda-4564-8863-e92b12fe3fe3,e072c187-0457-45f5-a19f-92dcb8cd4dcc,8baa13c6-28aa-4b1c-9516-097b89ee1136,48d2278c-1bc3-4f63-989e-98cafc9ca782,a0f6966c-6ae8-41ea-b802-2a6c1deae9ac,4a54bc07-5863-4ac8-a99c-23800e19319d,46bea349-cc96-4226-9273-40f73530c3b9,5d579362-579f-488e-a655-0028dc61bd6f,821eb7ca-1d93-417d-8503-e9368c00376c';
# SET @outbounds = '360.5665329,93.58615635,24.6604211,24.12089318,12.69290636,6.165247889,6.114823898,5.185094975,4.971224936,4.778427876,4.62224512,3.976006294,3.750780409,2.377537127,2.146692375,1.972302928,1.597289011,1.214823729'; -- 與 UUID 一一對應的 Outbound 值
SET @uuids = 'd6b0e51f-7f7d-46cb-8da2-06bc629c7642';
SET @outbounds = '0.0'; -- 與 UUID 一一對應的 Outbound 值

-- 定義時間範圍與間隔
SET @startTime = '2024-12-03 02:45:00';
SET @endTime = '2024-12-31 23:55:00';
SET @intervalMinutes = 5;

-- 創建存儲過程
DROP PROCEDURE IF EXISTS insert_from_arrays_with_interval;
DELIMITER //
CREATE PROCEDURE insert_from_arrays_with_interval()
BEGIN
    DECLARE currentTime DATETIME;
    DECLARE uuid VARCHAR(36);
    DECLARE outboundValue DECIMAL(10,2);
    DECLARE uuidArray TEXT;
    DECLARE outboundArray TEXT;
    DECLARE commaPos INT;

    -- 初始化時間和陣列
    SET currentTime = @startTime;
    SET uuidArray = @uuids;
    SET outboundArray = @outbounds;

    -- 時間循環
    WHILE currentTime <= @endTime DO
        -- 循環取出每個 UUID 和 Outbound
        WHILE uuidArray IS NOT NULL AND uuidArray != '' DO
            -- 找到 UUID 和 Outbound 的逗號分隔位置
            SET commaPos = INSTR(uuidArray, ',');

            -- 提取當前 UUID
            IF commaPos > 0 THEN
                SET uuid = SUBSTRING(uuidArray, 1, commaPos - 1);
                SET uuidArray = SUBSTRING(uuidArray, commaPos + 1);
            ELSE
                SET uuid = uuidArray;
                SET uuidArray = NULL;
            END IF;

            -- 提取對應的 Outbound 值
            SET commaPos = INSTR(outboundArray, ',');
            IF commaPos > 0 THEN
                SET outboundValue = CAST(SUBSTRING(outboundArray, 1, commaPos - 1) AS DECIMAL(10,2));
                SET outboundArray = SUBSTRING(outboundArray, commaPos + 1);
            ELSE
                SET outboundValue = CAST(outboundArray AS DECIMAL(10,2));
                SET outboundArray = NULL;
            END IF;

            -- 執行插入操作
            SET @sql = CONCAT(
#                'INSERT INTO VMResourceEdgeUsage (FKVMID, Outbound, CreateDate) ',
#                'VALUES (''', uuid, ''', ', outboundValue, ', ''', currentTime, ''');'
                 'INSERT INTO VMResourceUsage (FKVMID, Cpu, Ram, RamPercent, Disk, Diskpercent, Inbound, Outbound, AssignRam, AssignCpu, AssignDisk, CreateDate) ',
                 'VALUES (''', uuid, ''', 1.47, 282800.9472, 8.99, 30.396416, 94.9888, 0.0, ', outboundValue, ', 3145728.0, 2.0, 32.0, ''', currentTime, ''');'
            );
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END WHILE;

        -- 重置陣列並更新時間
        SET uuidArray = @uuids;
        SET outboundArray = @outbounds;
        SET currentTime = DATE_ADD(currentTime, INTERVAL @intervalMinutes MINUTE);
    END WHILE;
END;
//
DELIMITER ;

-- 執行存儲過程
CALL insert_from_arrays_with_interval();

-- 清理存儲過程
DROP PROCEDURE IF EXISTS insert_from_arrays_with_interval;
