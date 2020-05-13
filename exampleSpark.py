from pyspark.sql import SparkSession
from pyspark.sql.types import DateType
from pyspark.sql.types import DoubleType
from pyspark.sql.functions import desc
from pyspark.sql.functions import sum
from pyspark.sql.functions import date_format
from pyspark.sql.functions import avg

spark = SparkSession \
	.builder \
	.appName("PySpark example") \
	.getOrCreate()

#IMPORTANT: TENS DE FAZER DOWNLOAD DO CSV

df = spark \
	.read \
	.option("header", "false") \
	.csv("database/smallerLargeFile_3.csv")

dftypes = df \
	.withColumn("_c0", df["_c0"].cast(DateType()))

#dffilter = dftypes \
#		.filter(df["deadline"].between("2019-10-01","2019-12-01")) \
#		.orderBy(desc("deadline"))

#dftypes.printSchema()

dftypes.filter("_c1 == 'purchase'").select("_c1",date_format("_c0","E").alias("day of week"), "_c6").groupBy("day of week").agg(avg("_c6").alias("average price")).show()
#dftypes.show()
#dffilter.select(sum("pledged")).show()
spark.stop()
