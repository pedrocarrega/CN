from pyspark.sql import SparkSession
from pyspark.sql.types import DateType
from pyspark.sql.types import DoubleType
from pyspark.sql.functions import asc
from pyspark.sql.functions import desc
from pyspark.sql.functions import sum
from pyspark.sql.functions import date_format
from pyspark.sql.functions import avg
from pyspark.sql.functions import col
from pyspark.sql.functions import max
from pyspark.sql.functions import min
from pyspark.sql.functions import count
from pyspark.sql.functions import to_timestamp
from pyspark.sql.functions import round


spark = SparkSession \
	.builder \
	.appName("PySpark example") \
	.getOrCreate()

#IMPORTANT: TENS DE FAZER DOWNLOAD DO CSV
# GOAL: Calcular a duração de cada sessão arredondando aos minutos e calcular nessa sessão o ratio de purchase/cart, de seguida agrupar por intervalos da duração de sessão(por ex de 10 em 10 min) e calcular para cada grupo a média do ratio anteriormente calculado
df = spark \
	.read \
	.option("header", "false") \
	.csv("database/smallerLargeFile_3.csv")

session = df \
		  .select(to_timestamp(col("_c0"), 'yyyy-MM-dd HH:mm:ss').alias("time"), col("_c1").alias("event_type"), col("_c8").alias("session")) \
		  .filter(col("event_type").isNotNull() & col("session").isNotNull()) \
		  .groupby(col("session")) \
		  .agg(max(col("time")).alias("end_time"), min(col("time")).alias("start_time")) \
		  .withColumn("duration", round(((col("end_time").cast("long") - col("start_time").cast("long"))/60), 1)) \
		  .drop("start_time", "end_time") #\
		  #.agg(max("duration").alias("max"), sum("duration").alias("total")) \
		  #.agg(avg(col("max") / col("total")))

ratio = df \
		.select(col("_c1").alias("event_type"), col("_c8").alias("session")) \
		.filter(col("event_type").isNotNull() & col("session").isNotNull()) \
		.filter(col("event_type").contains("purchase") | col("event_type").contains("cart")) \
		.groupby(col("event_type"), col("session")) \
		.count() \
		.orderBy(asc("session"))

print(session.show())
print(ratio.show())


"""
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
			  .agg(max("count").alias("max"), sum("count").alias("total")) \
			  .agg(avg(col("max") / col("total")))

#print(views.show())
#print(purchases.show())
#print(views.join(purchases, purchases.user_session == views.user_session).drop("user_session", "event_type")).show())
print(result.show())
"""

spark.stop()