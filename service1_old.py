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
# GOAL: Numero medio de views ate uma compra
df = spark \
	.read \
	.option("header", "false") \
	.csv("database/smallerLargeFile_3.csv")


views = df \
		.select(col("_c8").alias("user_session"), col("_c1").alias("event_type")) \
		.filter(col("user_session").isNotNull()) \
		.filter(col("event_type").contains('view')) \
		.groupby(col("user_session"), col("event_type")) \
		.count()
		#.show()


purchases = df \
		.select(col("_c8").alias("user_session"), col("_c1").alias("event_type")) \
		.filter(col("user_session").isNotNull()) \
		.filter(col("event_type").contains('purchase'))
		#.drop("event_type") \
		#.show()

result = views.join(purchases, purchases.user_session == views.user_session) \
			  .agg(avg(col("count")))

#print(views.show())
#print(purchases.show())
#print(views.join(purchases, purchases.user_session == views.user_session).drop("user_session", "event_type")).show())
print(result.show())

spark.stop()