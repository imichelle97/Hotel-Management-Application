DROP DATABASE IF EXISTS hotelDB;
CREATE DATABASE hotelDB;
USE hotelDB;

DROP TABLE IF EXISTS user;
CREATE TABLE user (
	firstName VARCHAR(20) NOT NULL,
	lastName VARCHAR(20) NOT NULL,
	username VARCHAR(20) NOT NULL,
	password VARCHAR(20) NOT NULL,
	age INT NOT NULL,
	gender ENUM('M', 'F'),
	userRole ENUM('Customer', 'Manager', 'Room Attendant'),
	PRIMARY KEY(username)
);

DROP TABLE IF EXISTS room;
CREATE TABLE room (
	roomID INT(10) NOT NULL AUTO_INCREMENT,
	costPerNight DOUBLE(10,2) NOT NULL, 
	roomType VARCHAR(20) NOT NULL,
	PRIMARY KEY(roomID)
);


DROP TABLE IF EXISTS reservation;
CREATE TABLE reservation (
	reservationID INT AUTO_INCREMENT,
	roomID INT(10) NOT NULL,
	customerName VARCHAR(20) NOT NULL,
	startDate DATE NOT NULL,
	endDate DATE NOT NULL,
	totalNumOfDays INT(10),
	totalCost DOUBLE(10,2),
	cancelled BOOLEAN NOT NULL DEFAULT FALSE,
	updateOn TIMESTAMP  DEFAULT current_timestamp ON UPDATE current_timestamp,
	PRIMARY KEY(reservationID),
	FOREIGN KEY(roomID) references room(roomID),
	FOREIGN KEY(customerName) references user(username)
);
ALTER table reservation auto_increment = 1000;

DROP TABLE IF EXISTS roomService;
CREATE TABLE roomService (
	taskID INT(10) NOT NULL AUTO_INCREMENT,
	username VARCHAR(20) NOT NULL,
	task VARCHAR(20) NOT NULL,
	completedBy VARCHAR(20),
	reservationID  INT(10),
	updateOn TIMESTAMP NOT NULL DEFAULT current_timestamp ON UPDATE current_timestamp,
	PRIMARY KEY(taskID),
	FOREIGN KEY(completedBy) references user(username),
	FOREIGN KEY(username) references user(username),
	FOREIGN KEY(reservationID) references reservation(reservationID) 
);

DROP TABLE IF EXISTS complaint;
CREATE TABLE complaint(
	complaintID INT(20) NOT NULL AUTO_INCREMENT,
	customer VARCHAR(20) NOT NULL,
	complaint VARCHAR(150) NOT NULL,
	time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	resolvedBy VARCHAR(20),
	solution VARCHAR(150),
	updateOn TIMESTAMP NOT NULL DEFAULT current_timestamp ON UPDATE current_timestamp,
	PRIMARY KEY(complaintID),
	FOREIGN KEY(customer) references user(username),
	FOREIGN KEY(resolvedBy) references user(username)
);

DROP TABLE IF EXISTS ratingFeedback;
CREATE TABLE ratingFeedback (
	ratingID INT(20) NOT NULL AUTO_INCREMENT,
	customer VARCHAR(20) NOT NULL,
	rating INT NOT NULL,
	PRIMARY KEY(ratingID),
	FOREIGN KEY(customer) references user(username)
);

DROP TABLE IF EXISTS reservationArchive;
CREATE TABLE reservationArchive (
	reservationID INT(10) NOT NULL AUTO_INCREMENT,
	roomID INT(10) NOT NULL,
	customerName VARCHAR(20) NOT NULL,
	startDate DATE NOT NULL,
	endDate DATE NOT NULL,
	totalNumOfDays INT(10),
	totalCost DOUBLE(10,2),
	cancelled BOOLEAN NOT NULL DEFAULT FALSE,
	updateOn TIMESTAMP DEFAULT current_timestamp ON UPDATE current_timestamp,
	PRIMARY KEY(reservationID),
	FOREIGN KEY(roomID) references room(roomID),
	FOREIGN KEY(customerName) references user(username)
);
	
DROP TABLE IF EXISTS roomServiceArchive;
CREATE TABLE roomServiceArchive (
	taskID INT(10) NOT NULL AUTO_INCREMENT,
	username VARCHAR(20) NOT NULL,
	task VARCHAR(20) NOT NULL,
	completedBy VARCHAR(20),
	updateOn TIMESTAMP NOT NULL DEFAULT current_timestamp ON UPDATE current_timestamp,
	PRIMARY KEY(taskID),
	FOREIGN KEY(completedBy) references user(username),
	FOREIGN KEY(username) references user(username)
);

DROP TABLE IF EXISTS complaintArchive;
CREATE TABLE complaintArchive(
	complaintID INT(20) NOT NULL AUTO_INCREMENT,
	customer VARCHAR(20) NOT NULL,
	complaint VARCHAR(150) NOT NULL,
	time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
	resolvedBy VARCHAR(20),
	solution VARCHAR(150),
	updateOn TIMESTAMP NOT NULL DEFAULT current_timestamp ON UPDATE current_timestamp,
	PRIMARY KEY(complaintID),
	FOREIGN KEY(customer) references user(username),
	FOREIGN KEY(resolvedBy) references user(username)
);

insert into room(costPerNight, roomType)
values (89, "Single Room"),(89, "Single Room"),(89, "Single Room"),
(89, "Single Room"),(89, "Single Room"),(89, "Single Room"),
(89, "Single Room"),(89, "Single Room"),(89, "Single Room"),
(89, "Single Room"),(89, "Single Room"),(89, "Single Room"),
(112, "Double Room"),(112, "Double Room"),(112, "Double Room"),
(112, "Double Room"),(112, "Double Room"),(112, "Double Room"),
(112, "Double Room"),(112, "Double Room"),(112, "Double Room"),
(112, "Double Room"),(112, "Double Room"),(112, "Double Room"),
(164, "Suite Room"),(164, "Suite Room"),(164, "Suite Room"),
(164, "Suite Room"),(164, "Suite Room"),(164, "Suite Room"),
(164, "Suite Room"),(164, "Suite Room"),(164, "Suite Room"),
(164, "Suite Room"),(164, "Suite Room"),(164, "Suite Room"),
(200, "Platinum Suite"),(200, "Platinum Suite"),(200, "Platinum Suite"),
(200, "Platinum Suite"),(200, "Platinum Suite"),(200, "Platinum Suite");

insert into user(username, firstName, lastName, password, age, gender, userRole)
values('admin1', 'TestAdminF', 'TestAdminL', '123', 26, 'F', 'Manager');

insert into user(username, firstName, lastName, password, age, gender, userRole)
values('customer1', 'TestCustF', 'TestCustL', '2345', 21, 'F', 'Customer');

insert into user(username, firstName, lastName, password, age, gender, userRole)
values('roomattent1', 'RoomAttentF', 'RoomAttentL', '12345', 22, 'F', 'Room Attendant');

DROP PROCEDURE IF EXISTS archiveAll;
DELIMITER //
CREATE PROCEDURE archiveAll (IN cutoffDate TIMESTAMP)
BEGIN
	START TRANSACTION;
		
		INSERT INTO reservationArchive(reservationId,roomId,customerName,startDate,endDate,totalNumOfDays,
		                                totalCost,cancelled,updateOn)
		SELECT reservationId,roomId,customerName,startDate,endDate,totalNumOfDays,totalCost,cancelled,updateOn
		FROM reservation
		WHERE DATE(updatedOn) <= cutoffDate;

		INSERT INTO roomServiceArchive(taskId,username,task,completedBy,updateOn)
		SELECT taskId,username,task,completedBy,updateOn
		FROM roomservice
		WHERE DATE(updatedOn) <= cutoffDate;

		INSERT INTO complaintArchive(complaintId,customer,complaint,time,resolvedBy,solution,updateOn)
		SELECT complaintId,customer,complaint,time,resolvedBy,solution,updateOn
		FROM complaint
		WHERE DATE(updatedOn) <= cutoffDate;

		DELETE FROM RESERVATION WHERE DATE(updateOn) <= cutoffDate;
		DELETE FROM ROOMSERVICE WHERE DATE(updateOn) <= cutoffDate;
		DELETE FROM COMPLAINT WHERE DATE(updateOn) <= cutoffDate;
        
	COMMIT;
END;
//
DELIMITER ;
DROP TRIGGER IF EXISTS InsertRreservation;
DELIMITER //
Create trigger InsertRreservation
Before Insert on Reservation
For each row 
BEGIN
	IF EXISTS (Select startDate, endDate 
		From Reservation 
		Where (new.startDate <= endDate AND new.startDate >= startDate and new.roomID = roomID) OR 
		(new.endDate  >= startDate AND new.endDate <= endDate AND new.roomID = roomID))
        THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Date insert conflicts with another date';
END IF;
END; //
DELIMITER ;

DROP TRIGGER IF EXISTS DeleteRoomService;
delimiter //
CREATE TRIGGER DeleteRoomService
AFTER UPDATE ON reservation 
FOR EACH ROW
BEGIN
IF NEW.cancelled = TRUE  THEN
DELETE FROM roomService
where reservationID = NEW.reservationID;
END IF;
 END;
//
delimiter ; 