REGION=$1
STACK_NAME=$2

QUERY=$(cat <<-EOF
[
	Stacks[0].Outputs[?OutputKey==\`VpcId\`].OutputValue
]
EOF)


RESULTS=$(aws cloudformation describe-stacks \
	--stack-name $STACK_NAME \
	--region $REGION \
	--query "$QUERY" \
	--output text);
RESULTS_ARRAY=($RESULTS)

printf "${RESULTS_ARRAY[0]}\n"