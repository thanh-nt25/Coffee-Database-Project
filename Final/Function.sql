CREATE OR REPLACE FUNCTION update_total() RETURNS TRIGGER AS $$
BEGIN
	IF (TG_OP = 'INSERT') THEN
		UPDATE bills SET total = total + (SELECT price FROM foods WHERE foodid = NEW.foodid) * NEW.count WHERE billid = NEW.billid;
		ELSIF (TG_OP = 'DELETE') THEN
		UPDATE bills SET total = total - (SELECT price FROM foods WHERE foodid = NEW.foodid) * OLD.count WHERE billid = OLD.billid;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER update_total_trigger AFTER INSERT OR DELETE  ON billinfos FOR EACH ROW EXECUTE FUNCTION update_total();



CREATE OR REPLACE FUNCTION update_revenues() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.status = 1 AND OLD.status = 0) THEN
		IF EXISTS (SELECT * FROM revenues WHERE date = NEW.date) THEN
			UPDATE revenues SET total = total + NEW.total WHERE date = NEW.date;
		ELSE
			INSERT INTO revenues (date, total) VALUES (NEW.date, NEW.total);
		END IF;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_revenues_trigger AFTER UPDATE  ON bills FOR EACH ROW EXECUTE FUNCTION update_revenues();



CREATE FUNCTION dangky(PHONENUMBER_ varchar(20), DISPLAYNAME_ varchar(50), PASSWORD_ varchar(20))
RETURNS BOOLEAN AS $$
DECLARE
  duplicate_ BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM Accounts WHERE phonenumber = phonenumber_
  ) INTO duplicate_;


  IF duplicate_ THEN
    RETURN false;
  ELSE
    INSERT INTO accounts (phonenumber, displayname, password)
    VALUES (phonenumber_, displayname_, password_);


    RETURN true;
  END IF;
END;
$$ LANGUAGE PLPGSQL;
CREATE FUNCTION dangnhap(in_phonenumber VARCHAR(20), in_pass VARCHAR(20))
RETURNS BOOLEAN AS $$
DECLARE 
    passed BOOLEAN;
BEGIN
    SELECT (password = in_pass) INTO passed
    FROM accounts
    WHERE phonenumber = in_phonenumber;


    RETURN passed;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION bantrong()
RETURNS TABLE (
    ID int,
    tablename varchar(50)
) AS $$
BEGIN
    RETURN QUERY (
        SELECT tablefoods.tableid, tablefoods.tablename
        FROM tablefoods
		WHERE tablefoods.status = 0
    );
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION datban(phone_number VARCHAR(20), table_id INT)
RETURNS INT AS $$
DECLARE
	new_billid INT;
	table_status INT;
BEGIN
	SELECT status INTO table_status
	FROM TableFoods
	WHERE tableid = table_id;
	IF table_status = 0 THEN
		INSERT INTO Bills (phonenumber, tableid)
		VALUES (phone_number, table_id)
		RETURNING billid INTO new_billid;
		UPDATE TableFoods
		SET status = 1
		WHERE tablefoods.tableid = table_id;
		RETURN new_billid;
	ELSE
		RAISE EXCEPTION 'FALSE';
	END IF;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION getmenu(category_id INT)
RETURNS TABLE (
	ID int,	
	FOODNAME varchar(50),
	PRICE float
)
AS $$
BEGIN
RETURN QUERY
(
	SELECT f.foodid,f.foodname, f.price
	FROM Foods f
	WHERE (category_id = 0 OR f.categoryid = category_id)
);
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION datmon (bill_id INT, food_id INT, count_ INT)
RETURNS VOID AS $$
BEGIN
	INSERT INTO Billinfos(billid, foodid, count) VALUES (bill_id, food_id, count_);
END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION chuaphucvu()
RETURNS TABLE (
    billid INT,
    foodid INT,
    tablename varchar(50),
    foodname varchar(50),
    total INT
) AS $$
BEGIN
    RETURN QUERY (
        SELECT bills.billid, foods.foodid, tablefoods.tablename, foods.foodname, billinfos.count
        FROM billinfos
		JOIN bills ON billinfos.billid = bills.billid
		JOIN tablefoods ON bills.tableid = tablefoods.tableid
		JOIN foods ON billinfos.foodid = foods.foodid
		WHERE billinfos.status = '0'
    );
END;
$$ LANGUAGE plpgsql;



CREATE FUNCTION daphucvu(billid INT, foodid INT)
RETURNS BOOLEAN AS $$
BEGIN
        UPDATE billinfos
		SET status = '1'
		WHERE billinfos.billid = $1 AND billinfos.foodid = $2;
		
		IF FOUND THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION inhoadon(a INT)
RETURNS TABLE (
    "Số hoá đơn" int,
    "Bàn" varchar(50),
	"Tên món" varchar(50),
	"Số lượng" INT,
	"Tổng tiền" FLoat,
	"Trạng thái (được giao đến chưa ?)" INT,
	"Đã thanh toán ?"  INT
) AS $$
BEGIN
    RETURN QUERY (
        SELECT billinfos.billid, tablefoods.tablename,foods.foodname, billinfos.count ,(billinfos.count * foods.price), billinfos.status, bills.status
		FROM billinfos
		JOIN foods ON billinfos.foodid = foods.foodid
		JOIN bills ON billinfos.billid = bills.billid
		JOIN tablefoods ON bills.tableid = tablefoods.tableid
		WHERE billinfos.billid = (SELECT MAX(bills.billid) FROM bills WHERE tableid = a)
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION dathanhtoan(bill_id INT)
RETURNS BOOLEAN AS $$
BEGIN
        UPDATE bills
		SET status = '1'
		WHERE billid= bill_id;
		UPDATE bills
		SET timecheckout = CURRENT_TIME
		WHERE billid= bill_id;
		UPDATE tablefoods
		SET status = '0'
		WHERE tableid = (SELECT tableid FROM bills where billid= bill_id);
		IF FOUND THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
END;
$$ LANGUAGE plpgsql;