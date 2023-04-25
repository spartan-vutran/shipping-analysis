DROP TABLE if exists DateDimension;

CREATE TABLE DateDimension
(
  date_dim_id              INT NOT NULL,
  date_actual              DATE NOT NULL,
  epoch                    BIGINT NOT NULL,
  day_suffix               VARCHAR(4) NOT NULL,
  day_name                 VARCHAR(9) NOT NULL,
  day_of_week              INT NOT NULL,
  day_of_month             INT NOT NULL,
  day_of_quarter           INT NOT NULL,
  day_of_year              INT NOT NULL,
  week_of_month            INT NOT NULL,
  week_of_year             INT NOT NULL,
  week_of_year_iso         CHAR(10) NOT NULL,
  month_actual             INT NOT NULL,
  month_name               VARCHAR(9) NOT NULL,
  month_name_abbreviated   CHAR(3) NOT NULL,
  quarter_actual           INT NOT NULL,
  quarter_name             VARCHAR(9) NOT NULL,
  year_actual              INT NOT NULL,
  first_day_of_week        DATE NOT NULL,
  last_day_of_week         DATE NOT NULL,
  first_day_of_month       DATE NOT NULL,
  last_day_of_month        DATE NOT NULL,
  first_day_of_quarter     DATE NOT NULL,
  last_day_of_quarter      DATE NOT NULL,
  first_day_of_year        DATE NOT NULL,
  last_day_of_year         DATE NOT NULL,
  mmyyyy                   CHAR(6) NOT NULL,
  mmddyyyy                 CHAR(10) NOT NULL,
  weekend_indr             BOOLEAN NOT NULL
);

ALTER TABLE public.DateDimension ADD CONSTRAINT d_date_date_dim_id_pk PRIMARY KEY (date_dim_id);

CREATE INDEX d_date_date_actual_idx
  ON DateDimension(date_actual);

COMMIT;

INSERT INTO DateDimension
SELECT TO_CHAR(datum, 'yyyymmdd')::INT AS date_dim_id,
       datum AS date_actual,
       EXTRACT(EPOCH FROM datum) AS epoch,
       TO_CHAR(datum, 'fmDDth') AS day_suffix,
       TO_CHAR(datum, 'TMDay') AS day_name,
       EXTRACT(ISODOW FROM datum) AS day_of_week,
       EXTRACT(DAY FROM datum) AS day_of_month,
       datum - DATE_TRUNC('quarter', datum)::DATE + 1 AS day_of_quarter,
       EXTRACT(DOY FROM datum) AS day_of_year,
       TO_CHAR(datum, 'W')::INT AS week_of_month,
       EXTRACT(WEEK FROM datum) AS week_of_year,
       EXTRACT(ISOYEAR FROM datum) || TO_CHAR(datum, '"-W"IW-') || EXTRACT(ISODOW FROM datum) AS week_of_year_iso,
       EXTRACT(MONTH FROM datum) AS month_actual,
       TO_CHAR(datum, 'TMMonth') AS month_name,
       TO_CHAR(datum, 'Mon') AS month_name_abbreviated,
       EXTRACT(QUARTER FROM datum) AS quarter_actual,
       CASE
           WHEN EXTRACT(QUARTER FROM datum) = 1 THEN 'First'
           WHEN EXTRACT(QUARTER FROM datum) = 2 THEN 'Second'
           WHEN EXTRACT(QUARTER FROM datum) = 3 THEN 'Third'
           WHEN EXTRACT(QUARTER FROM datum) = 4 THEN 'Fourth'
           END AS quarter_name,
       EXTRACT(YEAR FROM datum) AS year_actual,
       datum + (1 - EXTRACT(ISODOW FROM datum))::INT AS first_day_of_week,
       datum + (7 - EXTRACT(ISODOW FROM datum))::INT AS last_day_of_week,
       datum + (1 - EXTRACT(DAY FROM datum))::INT AS first_day_of_month,
       (DATE_TRUNC('MONTH', datum) + INTERVAL '1 MONTH - 1 day')::DATE AS last_day_of_month,
       DATE_TRUNC('quarter', datum)::DATE AS first_day_of_quarter,
       (DATE_TRUNC('quarter', datum) + INTERVAL '3 MONTH - 1 day')::DATE AS last_day_of_quarter,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-01-01', 'YYYY-MM-DD') AS first_day_of_year,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-12-31', 'YYYY-MM-DD') AS last_day_of_year,
       TO_CHAR(datum, 'mmyyyy') AS mmyyyy,
       TO_CHAR(datum, 'mmddyyyy') AS mmddyyyy,
       CASE
           WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN TRUE
           ELSE FALSE
           END AS weekend_indr
FROM (SELECT '1970-01-01'::DATE + SEQUENCE.DAY AS datum
      FROM GENERATE_SERIES(0, 29219) AS SEQUENCE (DAY)
      GROUP BY SEQUENCE.DAY) DQ
ORDER BY 1;

COMMIT;


CREATE TABLE RegionDimension (
	RegionId integer NOT NULL PRIMARY KEY,
  Address varchar(100),
  StreetName varchar(32),
  TownOrCityName varchar(32),
  StateName varchar(32),
  Country varchar(32)
);


CREATE TABLE EmployeeDimension (
	EmployeeId varchar(36) NOT NULL PRIMARY KEY,
  EmployeeName varchar(32),
  HireDate date
);

CREATE TABLE ServiceTypeDimention (
	ServiceTypeId integer NOT NULL PRIMARY KEY,
  FromDistance decimal(7, 2), --From this distance the service type will be applied
  ToDistance decimal(7, 2), --TO this distance the service type will be applied
  ServiceType varchar(32), -- Value: short-distance, medium-distance, long-distances
  ServiceDescription varchar(32)
);

CREATE TABLE TripType (
	TripTypeId integer NOT NULL PRIMARY KEY,
  TripType varchar(32) -- Type:  One-round, Two-round
);




-------------
-- NOTE: I divide the requirements in to 2 fact tables for easily tracking the performance for 2 type of shipping type: In-house Employee and 3rd service:
-- + InHouseShippingFact: We want to know DistanceInKMiles which indicate number of km a employee drives.
-- + ServiceShippingFact: We want to know more about whether the cost we spend is paid off on different service: short-distance, medium-distance, long-distances
-------------

-- To track performance for awarding to employee
CREATE TABLE InHouseShippingFact (
	DateKey integer,
  ShipmentId integer PRIMARY KEY,
  EmployeeId varchar(36), -- We want to track employee
  RegionId integer,
  TripTypeId integer,


  DeliveryDurationInSecond integer,
  OnTimeDelivery decimal(3,2),
  DistanceInKMiles decimal(6,2), -- We want to know how many miles am employee has traveled
  ShipmentVolumeInUnit integer, -- We want to know The amount of volume an employee ship
  LossRate decimal(3,2),
  

  FOREIGN KEY(DateKey) REFERENCES DateDimension(date_dim_id) ON DELETE CASCADE,
  FOREIGN KEY(EmployeeId) REFERENCES EmployeeDimension(EmployeeId) ON DELETE CASCADE,
  FOREIGN KEY(RegionId) REFERENCES RegionDimension(RegionId) ON DELETE CASCADE,
  FOREIGN KEY(TripTypeId) REFERENCES TripType(TripTypeId) ON DELETE CASCADE
);


-- To track performance of the 3rd shipping service
CREATE TABLE ServiceShippingFact (
	DateKey integer,
  ShipmentId integer PRIMARY KEY,
  ServiceTypeId integer,  -- Assume Decision Maker only want to know which service we use to know how it affect the cost.
  RegionId integer,
  TripTypeId integer,

  DeliveryDurationInSecond integer,
  OnTimeDelivery decimal(3,2),
  DeliveryCostInDollar decimal(8,2),  -- We want to know the cost spending on service
  ShipmentVolumeInKg decimal(6,2),
  LossRate decimal(3,2),

  FOREIGN KEY(DateKey) REFERENCES DateDimension(date_dim_id) ON DELETE CASCADE,
  FOREIGN KEY(RegionId) REFERENCES RegionDimension(RegionId) ON DELETE CASCADE,
  FOREIGN KEY(ServiceTypeId) REFERENCES ServiceTypeDimention(ServiceTypeId) ON DELETE CASCADE,
  FOREIGN KEY(TripTypeId) REFERENCES TripType(TripTypeId) ON DELETE CASCADE
);

INSERT INTO TripType(TripTypeId, TripType) VALUES (0, 'One round'), (1, 'Two round');

INSERT INTO ServiceTypeDimention(ServiceTypeId, FromDistance, ToDistance,ServiceType, ServiceDescription) VALUES (0, 0, 3,'short-distance', 'Short-distance service'), (1, 3, 10, 'medium-distance', 'medium-distance service'), (2, 10, 20, 'long-distance', 'long-distance service');