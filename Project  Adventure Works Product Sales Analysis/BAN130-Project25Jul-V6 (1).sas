/*********************************************************************************/
/*NCC BAN130 Project: Group 8
Project Name: Adventure Works Product Sales Analysis
Team Members: Aaron, Goushalya,Parin, Sambhav, Sidek
Date: July 20, 2021*/
/*********************************************************************************/

/****************************  STEP 1 - Data Import ******************************/

libname AdvWorks '/home/u58659328/130 assignments/project'; 

/*Creating Product dataset from the available data file*/

Proc Import datafile = '/home/u58659328/130 assignments/project/AdventureWorks.xlsx'
	out  =  AdvWorks.Product
	dbms  =  xlsx
	replace
	;
	sheet  =  "Product";
Run;

Title "Listing of Product";
Proc Print Data=AdvWorks.Product(obs=5);
Run;

Title "Contents and Description for Product";
Proc Contents Data = AdvWorks.Product;
Run;

/*Creating SalesOrderDetail dataset from the available data file*/

Proc import datafile = '/home/u58659328/130 assignments/project/AdventureWorks.xlsx'
	out  =  AdvWorks.SalesOrderDetail
	dbms  =  xlsx
	replace
	;
	sheet  =  "SalesOrderDetail";
Run;

Title "Listing of SalesOrderDetail";
Proc Print Data=AdvWorks.SalesOrderDetail(obs=5);
Run;

Title "Contents and Description for SalesOrderDetail";
Proc Contents Data =AdvWorks.SalesOrderDetail;
Run;

/****************************  STEP 2 - Data Cleaning ******************************/

/****************************    2.1 Product_Clean    ******************************/

/*Creating Product_Clean dataset with selected variables from Product dataset*/

Data AdvWorks.Product_Clean; 
	Set AdvWorks.Product (Keep=ProductID Name ProductNumber Color ListPrice);
Run;

Title "Listing of Product_Clean";
Proc Print Data=AdvWorks.Product_Clean(obs=5);
Run;

Title "Contents and Description for Product";
Proc Contents Data = AdvWorks.Product_Clean varnum;
Run;

/*Replacing Missing Values in Color variable by 'NA' */

Data AdvWorks.Product_Clean; 
	Set AdvWorks.Product_Clean;
	If missing(color) then Color='NA';
Run;

/* Checking frequency of Color variable after missing values are replaced with 'NA' */
Proc Freq Data = AdvWorks.Product_Clean;
	Table Color;
Run;

/* Inference : 248 missing values in Color variable are replaced by 'NA' */

/* Converting ListPrice variable to numeric datatype and formatting */

Data AdvWorks.Product_Clean; 
	Set AdvWorks.Product_Clean;
	ListPrice_num=input(ListPrice,dollar20.2);
	format ListPrice_num dollar20.2;
	drop ListPrice;
rename ListPrice_num=ListPrice;
Run;

Title "Listing of Product_Clean";
Proc Print Data=AdvWorks.Product_Clean(obs=5);
Run; 


/****************************    2.2 SalesOrderDetail_Clean    ******************************/

/*Creating SalesOrderDetail_Clean dataset with selected variables from SalesOrderDetail dataset*/

Data AdvWorks.SalesOrderDetail_Clean; 
	Set AdvWorks.SalesOrderDetail (Keep=SalesOrderID SalesOrderDetailID OrderQty ProductID UnitPrice LineTotal ModifiedDate);
Run;

Title "Listing of SalesOrderDetail_Clean";
Proc Print Data=AdvWorks.SalesOrderDetail_Clean(obs=5);
Run;

Title "Contents and Description for SalesOrderDetail";
Proc Contents Data = AdvWorks.SalesOrderDetail_Clean varnum;
Run;
	
Data AdvWorks.SalesOrderDetail_Clean; 
	Set AdvWorks.SalesOrderDetail_Clean;
	ModifiedDate_num=input(ModifiedDate,yymmdd10.);
	UnitPrice_num=input(UnitPrice,dollar20.2);
	LineTotal_num=input(LineTotal,dollar20.2);
	OrderQty_num=input(OrderQty,3.);
	format UnitPrice_num LineTotal_num dollar20.2;
	format ModifiedDate_num mmddyy10.;
	drop ModifiedDate UnitPrice LineTotal OrderQty;
	rename ModifiedDate_num=ModifiedDate UnitPrice_num=UnitPrice LineTotal_num=LineTotal OrderQty_num=OrderQty;
Run;

Title "Listing of SalesOrderDetail_Clean";
Proc Print Data=AdvWorks.SalesOrderDetail_Clean(obs=5);
Run;
	
Title "Contents and Description for SalesOrderDetail";
Proc Contents Data = AdvWorks.SalesOrderDetail_Clean varnum;
Run;

/* Including date for year 2013 and 2014 in ModifiedDate */
Data AdvWorks.SalesOrderDetail_Clean; 
	Set AdvWorks.SalesOrderDetail_Clean (where=(year(ModifiedDate) in (2013,2014)));
Run;

Title "Listing of SalesOrderDetail_Clean";
Proc Print Data=AdvWorks.SalesOrderDetail_Clean(obs=5);
Run;

/**************************** STEP 3 - 	Joining and Merging ****************************/

/*****************************    3.1 Creating SalesDetails Dataset  *******************/

/*Sorting SalesOrderDetail_Clean by ProductID*/
Proc Sort Data = AdvWorks.SalesOrderDetail_Clean;
    by ProductID;
Run;

/*Sorting Product_Clean by ProductID*/ 
Proc Sort Data = AdvWorks.Product_Clean;
    by ProductID;
Run;

/*Create a SalesDetails dataset by joining SalesOrderDetail_Clean and Product_Clean datasets by ProductID*/
Data AdvWorks.SalesDetails;
    merge  AdvWorks.SalesOrderDetail_Clean(in=DS1) AdvWorks.Product_Clean;
    by ProductID;
    if DS1;
    Drop SalesOrderID SalesOrderDetailID ProductNumber ListPrice;
Run;

Title "Listing of SalesDetails";
Proc print data=AdvWorks.SalesDetails(obs=5);
run;


/**************************   3.2 Creating a SalesAnalysis Dataset  *********************/

Title "Creating SalesAnalysis Dataset with SubTotal SubOrderQty";
Proc Summary Data=AdvWorks.SalesDetails;
by ProductId;
    ID ModifiedDate UnitPrice LineTotal OrderQty Name Color;
    Var LineTotal OrderQty  ;
    Output out=AdvWorks.SalesAnalysis(Drop=_type_ _freq_) Sum=SubTotal SubOrderQty;
Run;

/* Formatting SubTotal Variable */
Data AdvWorks.SalesAnalysis;
	Set AdvWorks.SalesAnalysis;
	Format SubTotal dollar11.2;
Run;

Title "Listing of SalesAnalysis";
Proc Print Data=AdvWorks.SalesAnalysis(Obs=5);
run;

/* Alternate Approach 
Data AdvWorks.SalesAnalysis;
	Set Advworks.SalesDetails;
	by ProductId;
	if first.ProductId then SubTotal=0 ;
		Subtotal+ LineTotal ;
		if first.ProductId then SubOrderQty=0;
			SubOrderQty+ OrderQty;
		if last.ProductId;
	if last.ProductId;
format subtotal dollar11.2;
run;
*/

/**************************** STEP 4 - 	Data Analysis  ****************************/


proc sort data=advworks.salesanalysis out=sales_color;
	by color;
run;

/* 1.	How many Red color Helmets are sold in 2013 and 2014? */
Title 'Total sale of Red color Helmet';

proc print data=sales_color;
	sum suborderqty;
	where name='Sport-100 Helmet, Red';
run;

/* A. 4657 */


/* 	How many items sold in 2013 and 2014 have a Multi color? */

title 'Total number of sale of Multi color products ';

proc print data=sales_color;
	sum suborderqty;
	where color='Multi';
run;

/* A.  15009 */


/*  What is the combined Sales total for all the helmets sold in 2013 and 2014? */


title 'Total sales revenue of Helmet';
proc print data=sales_color;
	where find(name, "Helmet", "i");
	sum subtotal;
run;

/* A. $381,800.34 */


/* 	How many Yellow Color Touring-1000 where sold in 2013 and 2014? */
proc print data=sales_color;
	sum suborderqty;
	where name contains ('Touring-1000 Yellow');
run;

/* A. 3168 */

/*	What was the total sales in 2013 and 2014? */

Title 'Total sales in the year 2013 and 2014';
proc print data=sales_color;
	sum subtotal;
	format subtotal dollar11.2;
run;

/*  $63680407.86  */

/* Barchart  */

proc sgplot data = advworks.salesanalysis;
vbar color;
title 'Sales by Color';
run;

/******************************************************************************/





















