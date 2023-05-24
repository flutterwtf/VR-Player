min_coverage=75

coverage_check=$(flutter pub run test_cov_console --pass=$min_coverage)

if [ "$coverage_check" == "PASSED" ]
then
  echo "Good coverage"
  exit 0
else
  echo "Coverage less than $min_coverage"
  exit 1
fi