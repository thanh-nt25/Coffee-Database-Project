CREATE TABLE FoodCategorys (
  categoryid SERIAL PRIMARY KEY,
  categoryname VARCHAR(25) NOT NULL
);

CREATE TABLE Foods (
  foodid SERIAL PRIMARY KEY,
  foodname VARCHAR(50) NOT NULL,
  categoryid INT NOT NULL,
  price FLOAT NOT NULL,
  FOREIGN KEY (categoryid) REFERENCES FoodCategorys(categoryid)
);

CREATE TABLE TableFoods (
  tableid INT PRIMARY KEY,
  tablename VARCHAR(25) NOT NULL,
  status INT DEFAULT 0
);

CREATE TABLE Accounts (
  phonenumber VARCHAR(20) PRIMARY KEY,
  displayname VARCHAR(50) NOT NULL,
  password VARCHAR(20) NOT NULL,
  type INT DEFAULT 0
);

CREATE TABLE Bills (
  billid SERIAL PRIMARY KEY,
  phonenumber VARCHAR(20) NOT NULL,
  timecheckin TIME DEFAULT CURRENT_TIME,
  timecheckout TIME DEFAULT '00:00:00',
  date DATE DEFAULT CURRENT_DATE,
  tableid INT NOT NULL, -- tham chieu den tableid trong tablefoods
  status INT DEFAULT 0,
  total FLOAT DEFAULT 0,
  FOREIGN KEY (phonenumber) REFERENCES Accounts(phonenumber),
  FOREIGN KEY (tableid) REFERENCES TableFoods(tableid)
);

CREATE TABLE BillInfos (
  billid INT NOT NULL,
  foodid INT NOT NULL,
  count INT NOT NULL,
  status INT DEFAULT 0,
  PRIMARY KEY (billid, foodid),
  FOREIGN KEY (billid) REFERENCES Bills(billid),
  FOREIGN KEY (foodid) REFERENCES Foods(foodid)
);

CREATE TABLE Revenues (
  date DATE PRIMARY KEY,
  total FLOAT NOT NULL
);