output "budget_name" {
  description = "Name of the monthly AWS budget"
  value       = aws_budgets_budget.monthly.name
}

