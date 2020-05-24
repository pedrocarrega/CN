BUCKET_NAME=$1

echo "from pyspark.sql import SparkSession
import pyspark.sql.functions as fn
from pyspark.sql.functions import *
import pyspark

spark = SparkSession \\
        .builder \\
        .appName(\"PySpark example\") \\
        .getOrCreate()

df = spark \\
        .read \\
        .option(\"header\",\"true\") \\
        .option(\"inferSchema\",\"true\") \\
        .csv(\"gs://$BUCKET_NAME/dataset.csv\") \\

cnt_cond = lambda cond: fn.sum(fn.when(cond, 1).otherwise(0))
gdf = df \\
        .groupBy(\"user_id\") \\
        .agg(
                cnt_cond(fn.col('event_type') == 'purchase').alias('no_purchases'),
                countDistinct('category_id').alias('visited_categories')
        ) \\
        .filter(fn.col('no_purchases') > 0) \\
        .withColumn('avg_categories_per_purchase',(fn.col('visited_categories')/fn.col('no_purchases'))) \\
        .agg(
                avg(col('avg_categories_per_purchase')).alias('average_categories_per_purchase')
        )

gdf.write.format('csv').save(\"gs://$BUCKET_NAME/output\")
print(\"== Row count: \", gdf.count(), \" ==\")
spark.stop()
" > Query2.py