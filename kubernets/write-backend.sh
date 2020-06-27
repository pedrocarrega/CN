PROJECT_NAME=$1
BUCKET_NAME=$2

echo "const express = require(\"express\");
const fs = require('fs');
let router = express.Router();


module.exports = router;

router
    .route(\"/\")
    .get((req, res) => {
        res.status(200).send(\"No issues here, keep moving.\n\")
    });

router
    .route(\"/svc2\")
		.get((req, res) => {
		const dataproc = require('@google-cloud/dataproc');
		const {Storage} = require('@google-cloud/storage');

		// Create a cluster client with the endpoint set to the desired cluster region
		const clusterClient = new dataproc.v1.ClusterControllerClient({
			apiEndpoint: \`europe-west1-dataproc.googleapis.com\`,
			projectId: '$PROJECT_NAME',
			keyFilename: \"creds.json\",
		});

		// Create a job client with the endpoint set to the desired cluster region
		const jobClient = new dataproc.v1.JobControllerClient({
			apiEndpoint: \`europe-west1-dataproc.googleapis.com\`,
			projectId: '$PROJECT_NAME',
			keyFilename: \"creds.json\",
		});

		async function quickstart() {

			//Total of 2 vCPUs since quotas are limited, leaving 6 vCPUs for kubernetes cluster
			const cluster = {
				projectId: '$PROJECT_NAME',
				region: 'europe-west1',
				cluster: {
					clusterName:'ecommerce-cluster',
					config: {
						masterConfig: {
							numInstances: 1,
							machineTypeUri: 'n1-standard-1',
						},
						workerConfig: {
							numInstances: 2,
							machineTypeUri: 'n1-standard-2',
						},
					},
				},
			};

			// Create the cluster
			const [operation] = await clusterClient.createCluster(cluster);
			const [response] = await operation.promise();
			console.log(\`Cluster created successfully: \${response.clusterName}\`);

			const job = {
				projectId: '$PROJECT_NAME',
				region: 'europe-west1',
				job: {
					placement: {
						clusterName: 'ecommerce-cluster',
					},
					pysparkJob: {
						mainPythonFileUri: 'gs://$BUCKET_NAME/Query2.py',
					},
				},
			};

			let [jobResp] = await jobClient.submitJob(job);
			const jobId = jobResp.reference.jobId;

			console.log(\`Submitted job \"\${jobId}\".\`);

			// Terminal states for a job
			const terminalStates = new Set(['DONE', 'ERROR', 'CANCELLED']);

			// Create a timeout such that the job gets cancelled if not
			// in a termimal state after a fixed period of time.
			const timeout = 600000;
			const start = new Date();

			// Wait for the job to finish.
			const jobReq = {
				projectId: '$PROJECT_NAME',
				region: 'europe-west1',
				jobId: jobId,
			};

			while (!terminalStates.has(jobResp.status.state)) {
				if (new Date() - timeout > start) {
					await jobClient.cancelJob(jobReq);
					console.log(
						\`Job \${jobId} timed out after threshold of \` +
						\`\${timeout / 60000} minutes.\`
					);
					break;
				}
				[jobResp] = await jobClient.getJob(jobReq);
			}

			const clusterReq = {
				projectId: '$PROJECT_NAME',
				region: 'europe-west1',
				clusterName: 'ecommerce-cluster',
			};

			const storage = new Storage({
				projectId: '$PROJECT_NAME',
				keyFilename: 'creds.json'
			});

			const [test] = await storage
				.bucket('$BUCKET_NAME')
				.getFiles({prefix: 'output'});

			/*function deleteFiles(){
				test.forEach(async file => {
					await file.delete();
				});
			}*/

			async function getResult(){
				var i;
				for(i = 0; i < test.length; i++){
					console.log(\"FILE \" + i + \"VALUE IS: \" + test[i]);
				}
				await storage.bucket('$BUCKET_NAME')
					.file(test[2].name)
					.download({destination: 'OUTPUT.txt'});
				
				fs.readFile('OUTPUT.txt', function read(err, data){
					if(err){
						res.status(400).send(err);
						throw err;
					}else{
						res.status(200).send(data);
						//callback();
					}
				});
			}

			getResult();

			// Output a success message.
			console.log(
				\`Job \${jobId} finished with state \${jobResp.status.state}\`
			);

			// Delete the cluster once the job has terminated.

			const [deleteOperation] = await clusterClient.deleteCluster(clusterReq);
			await deleteOperation.promise();

			// Output a success message
			console.log(\`Cluster successfully deleted.\`);
			console.log(\"Finished.\");
		}
		quickstart();
});

router
    .route(\"/svc1\")
		.get((req, res) => {
		const dataproc = require('@google-cloud/dataproc');
		const {Storage} = require('@google-cloud/storage');

		// Create a cluster client with the endpoint set to the desired cluster region
		const clusterClient = new dataproc.v1.ClusterControllerClient({
			apiEndpoint: \`europe-west1-dataproc.googleapis.com\`,
			projectId: '$PROJECT_NAME',
			keyFilename: \"creds.json\",
		});

		// Create a job client with the endpoint set to the desired cluster region
		const jobClient = new dataproc.v1.JobControllerClient({
			apiEndpoint: \`europe-west1-dataproc.googleapis.com\`,
			projectId: '$PROJECT_NAME',
			keyFilename: \"creds.json\",
		});

		async function quickstart() {

			//Total of 2 vCPUs since quotas are limited, leaving 6 vCPUs for kubernetes cluster
			const cluster = {
				projectId: '$PROJECT_NAME',
				region: 'europe-west1',
				cluster: {
					clusterName:'ecommerce-cluster',
					config: {
						masterConfig: {
							numInstances: 1,
							machineTypeUri: 'n1-standard-1',
						},
						workerConfig: {
							numInstances: 2,
							machineTypeUri: 'n1-standard-2',
						},
					},
				},
			};

			// Create the cluster
			const [operation] = await clusterClient.createCluster(cluster);
			const [response] = await operation.promise();
			console.log(\`Cluster created successfully: \${response.clusterName}\`);

			const job = {
				projectId: '$PROJECT_NAME',
				region: 'europe-west1',
				job: {
					placement: {
						clusterName: 'ecommerce-cluster',
					},
					pysparkJob: {
						mainPythonFileUri: 'gs://$BUCKET_NAME/Query1.py',
					},
				},
			};

			let [jobResp] = await jobClient.submitJob(job);
			const jobId = jobResp.reference.jobId;

			console.log(\`Submitted job \"\${jobId}\".\`);

			// Terminal states for a job
			const terminalStates = new Set(['DONE', 'ERROR', 'CANCELLED']);

			// Create a timeout such that the job gets cancelled if not
			// in a termimal state after a fixed period of time.
			const timeout = 600000;
			const start = new Date();

			// Wait for the job to finish.
			const jobReq = {
				projectId: '$PROJECT_NAME',
				region: 'europe-west1',
				jobId: jobId,
			};

			while (!terminalStates.has(jobResp.status.state)) {
				if (new Date() - timeout > start) {
					await jobClient.cancelJob(jobReq);
					console.log(
						\`Job \${jobId} timed out after threshold of \` +
						\`\${timeout / 60000} minutes.\`
					);
					break;
				}
				[jobResp] = await jobClient.getJob(jobReq);
			}

			const clusterReq = {
				projectId: '$PROJECT_NAME',
				region: 'europe-west1',
				clusterName: 'ecommerce-cluster',
			};

			const storage = new Storage({
				projectId: '$PROJECT_NAME',
				keyFilename: 'creds.json'
			});

			const [test] = await storage
				.bucket('$BUCKET_NAME')
				.getFiles({prefix: 'output'});

			/*function deleteFiles(){
				test.forEach(async file => {
					await file.delete();
				});
			}*/

			async function getResult(){
				var i;
				for(i = 0; i < test.length; i++){
					console.log(\"FILE \" + i + \"VALUE IS: \" + test[i]);
				}
				await storage.bucket('$BUCKET_NAME')
					.file(test[2].name)
					.download({destination: 'OUTPUT.txt'});
				
				fs.readFile('OUTPUT.txt', function read(err, data){
					if(err){
						res.status(400).send(err);
						throw err;
					}else{
						res.status(200).send(data);
						//callback();
					}
				});
			}

			getResult();

			// Output a success message.
			console.log(
				\`Job \${jobId} finished with state \${jobResp.status.state}\`
			);

			// Delete the cluster once the job has terminated.

			const [deleteOperation] = await clusterClient.deleteCluster(clusterReq);
			await deleteOperation.promise();

			// Output a success message
			console.log(\`Cluster successfully deleted.\`);
			console.log(\"Finished.\");
		}
		quickstart();
});

router
    .route(\"/svc3\")
		.get((req, res) => {
		const dataproc = require('@google-cloud/dataproc');
		const {Storage} = require('@google-cloud/storage');

		// Create a cluster client with the endpoint set to the desired cluster region
		const clusterClient = new dataproc.v1.ClusterControllerClient({
			apiEndpoint: \`europe-west1-dataproc.googleapis.com\`,
			projectId: '$PROJECT_NAME',
			keyFilename: \"creds.json\",
		});

		// Create a job client with the endpoint set to the desired cluster region
		const jobClient = new dataproc.v1.JobControllerClient({
			apiEndpoint: \`europe-west1-dataproc.googleapis.com\`,
			projectId: '$PROJECT_NAME',
			keyFilename: \"creds.json\",
		});

		async function quickstart() {

			//Total of 2 vCPUs since quotas are limited, leaving 6 vCPUs for kubernetes cluster
			const cluster = {
				projectId: '$PROJECT_NAME',
				region: 'europe-west1',
				cluster: {
					clusterName:'ecommerce-cluster',
					config: {
						masterConfig: {
							numInstances: 1,
							machineTypeUri: 'n1-standard-1',
						},
						workerConfig: {
							numInstances: 2,
							machineTypeUri: 'n1-standard-2',
						},
					},
				},
			};

			// Create the cluster
			const [operation] = await clusterClient.createCluster(cluster);
			const [response] = await operation.promise();
			console.log(\`Cluster created successfully: \${response.clusterName}\`);

			const job = {
				projectId: '$PROJECT_NAME',
				region: 'europe-west1',
				job: {
					placement: {
						clusterName: 'ecommerce-cluster',
					},
					pysparkJob: {
						mainPythonFileUri: 'gs://$BUCKET_NAME/Query3.py',
					},
				},
			};

			let [jobResp] = await jobClient.submitJob(job);
			const jobId = jobResp.reference.jobId;

			console.log(\`Submitted job \"\${jobId}\".\`);

			// Terminal states for a job
			const terminalStates = new Set(['DONE', 'ERROR', 'CANCELLED']);

			// Create a timeout such that the job gets cancelled if not
			// in a termimal state after a fixed period of time.
			const timeout = 600000;
			const start = new Date();

			// Wait for the job to finish.
			const jobReq = {
				projectId: '$PROJECT_NAME',
				region: 'europe-west1',
				jobId: jobId,
			};

			while (!terminalStates.has(jobResp.status.state)) {
				if (new Date() - timeout > start) {
					await jobClient.cancelJob(jobReq);
					console.log(
						\`Job \${jobId} timed out after threshold of \` +
						\`\${timeout / 60000} minutes.\`
					);
					break;
				}
				[jobResp] = await jobClient.getJob(jobReq);
			}

			const clusterReq = {
				projectId: '$PROJECT_NAME',
				region: 'europe-west1',
				clusterName: 'ecommerce-cluster',
			};

			const storage = new Storage({
				projectId: '$PROJECT_NAME',
				keyFilename: 'creds.json'
			});

			const [test] = await storage
				.bucket('$BUCKET_NAME')
				.getFiles({prefix: 'output'});

			/*function deleteFiles(){
				test.forEach(async file => {
					await file.delete();
				});
			}*/

			async function getResult(){
				var i;
				for(i = 0; i < test.length; i++){
					console.log(\"FILE \" + i + \"VALUE IS: \" + test[i]);
				}

				await storage.bucket('$BUCKET_NAME')
					.file(test[2].name)
					.download({destination: 'OUTPUT.txt'});
				
				fs.readFile('OUTPUT.txt', function read(err, data){
					if(err){
						res.status(400).send(err);
						throw err;
					}else{
						res.status(200).send(data);
						//callback();
					}
				});
			}

			getResult();

			// Output a success message.
			console.log(
				\`Job \${jobId} finished with state \${jobResp.status.state}\`
			);

			// Delete the cluster once the job has terminated.

			const [deleteOperation] = await clusterClient.deleteCluster(clusterReq);
			await deleteOperation.promise();

			// Output a success message
			console.log(\`Cluster successfully deleted.\`);
			console.log(\"Finished.\");
		}
		quickstart();
});" > spark-svc/routes/spark.js