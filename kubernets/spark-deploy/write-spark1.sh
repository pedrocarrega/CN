BUCKET_NAME=$1

echo "from pyspark.sql import SparkSession
from pyspark.sql.types import DateType
from pyspark.sql.types import IntegerType
from pyspark.sql.types import StringType
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
from pyspark.sql.functions import udf
from pyspark.sql.functions import round
from pyspark.sql.functions import lit
from pyspark.sql.functions import when
import math

interval = 60.0

def range_interval(duration):
	temp = interval
	while(True):
		if duration < temp:
			return '<' + str(temp)
		temp+=interval

def divide(cart, purchase):
	return int(math.ceil(cart/purchase))


udf_divide = udf(divide, IntegerType())
udf_intervals = udf(range_interval, StringType())

spark = SparkSession \\
	.builder \\
	.appName(\"PySpark example\") \\
	.getOrCreate()

#IMPORTANT: TENS DE FAZER DOWNLOAD DO CSV
#GOAL: Calcular a duracao de cada sessao arredondando aos minutos e calcular nessa sessao o ratio de purchase/cart, de seguida agrupar por intervalos da duracao de sessao(por ex de 10 em 10 min) e calcular para cada grupo a media do ratio anteriormente calculado
df = spark \\
	.read \\
	.option(\"header\", \"false\") \\
	.csv(\"gs://$BUCKET_NAME/dataset.csv\") \\


		  
cart = df \
		.select(col(\"_c1\").alias(\"event_type\"), col(\"_c8\").alias(\"sessions\")) \\
		.filter(col(\"event_type\").isNotNull() & col(\"sessions\").isNotNull()) \\
		.filter(col(\"event_type\").contains(\"cart\")) \\
		.groupby(col(\"event_type\"), col(\"sessions\")) \\
		.count().withColumnRenamed(\"count\", \"#cart\") \\


purchases = df \\
		.select(col(\"_c1\").alias(\"event_type\"), col(\"_c8\").alias(\"session\")) \\
		.filter(col(\"event_type\").isNotNull() & col(\"session\").isNotNull()) \\
		.filter(col(\"event_type\").contains(\"purchase\")) \\
		.groupby(col(\"event_type\"), col(\"session\")) \\
		.count().withColumnRenamed(\"count\", \"#purchases\")

ratio = cart \\
		.join(purchases, cart.sessions == purchases.session) \\
		.withColumn(\"ratio\", udf_divide(\"#cart\", \"#purchases\")) \\
		.drop(\"session\", \"event_type\", \"#cart\", \"#purchases\")

session = df \\
		  .select(to_timestamp(col(\"_c0\"), 'yyyy-MM-dd HH:mm:ss').alias(\"time\"), col(\"_c8\").alias(\"session\")) \\
		  .filter(col(\"session\").isNotNull()) \\
		  .groupby(col(\"session\")) \\
		  .agg(max(col(\"time\")).alias(\"end_time\"), min(col(\"time\")).alias(\"start_time\")) \
		  .withColumn(\"duration\", round(((col(\"end_time\").cast(\"long\") - col(\"start_time\").cast(\"long\"))/60), 1)) \\
		  .drop(\"start_time\", \"end_time\") \\
		  .filter(\"duration > 0.0 AND duration < 600.0\") \\
		  .withColumn(\"intervals\", udf_intervals(\"duration\"))
		  

result = ratio \\
		 .join(session, session.session == ratio.sessions)

temp = spark.createDataFrame([('<0.0', 0)], ['interval', 'ratio'])

for i in range(int(interval), int(interval)*10+1, int(interval)):
	i = float(i)
	
	value = result.filter(col(\"intervals\").contains(('<' + str(i)))).agg(avg(col(\"ratio\"))).collect()[0][\"avg(ratio)\"]
	if value == None:
		value = 0
	
	temp = temp.union(spark.createDataFrame([(('<' + str(i)), int(math.ceil(value)))], ['interval', 'ratio']))


result = result \\
			.groupby(\"intervals\").count() \\
			.orderBy(desc(\"intervals\")) \\
			.join(temp, temp.interval == result.intervals) \\
			.drop(\"interval\")

result.write.format('csv').save(\"gs://$BUCKET_NAME/output\")

spark.stop()" > Query1.py