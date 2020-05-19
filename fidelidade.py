from pyspark.sql import SparkSession
from pyspark.sql.types import DateType
from pyspark.sql.types import DoubleType
from pyspark.sql.functions import asc
from pyspark.sql.functions import sum
from pyspark.sql.functions import date_format
from pyspark.sql.functions import avg
from pyspark.sql.functions import col
from pyspark.sql.functions import max
from pyspark.sql.functions import count

spark = SparkSession \
	.builder \
	.appName("PySpark example") \
	.getOrCreate()

#IMPORTANT: TENS DE FAZER DOWNLOAD DO CSV
# GOAL: Media de fidelidade a uma marca dentro de uma categoria, para cada user
df = spark \
	.read \
	.option("header", "false") \
	.csv("database/smallerLargeFile_3.csv")

max_by_brand = df \
		.select(col("_c3").alias("category_id"),col("_c4").alias("category_code"), col("_c5").alias("brand"), col("_c7").alias("user_id")) \
		.filter(col("brand").isNotNull()) \
		.groupBy("user_id", "category_id", "brand") \
		.count() \
		.groupBy("user_id", "category_id") \
		.agg(max("count").alias("max"), sum("count").alias("total")) \
		.agg(avg(col("max") / col("total"))).show()
		
spark.stop()


