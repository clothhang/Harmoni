local maniaGrades = {}

maniaGrades.getGrade = function(accuracy)
    if not accuracy then return end
    local grades = maniaGrades.getGrades_PLURAL_that_is_grades_WITH_AN_S__this_function_gives_you_the_TABLE_of_grades___this_is_NOT_the_one_that_gives_the_current_grade_when_you_pass_in_an_accuracy___that_is_the_OTHER_similarly_named_function_called_getGrade__that_is_not_THIS_one()
    for i, grade in ipairs(grades) do
        if accuracy >= grade.accuracy then
            return grade
        end
    end
end

maniaGrades.getGrades_PLURAL_that_is_grades_WITH_AN_S__this_function_gives_you_the_TABLE_of_grades___this_is_NOT_the_one_that_gives_the_current_grade_when_you_pass_in_an_accuracy___that_is_the_OTHER_similarly_named_function_called_getGrade__that_is_not_THIS_one = function()
    return {
        {grade = "X", accuracy = 100, color = {0,0,0}},
        {grade = "S", accuracy = 95, color = rgb({0 ,91.8, 100})},
        {grade = "A", accuracy = 90, color = rgb({0, 10.2, 88.2})},
        {grade = "B", accuracy = 80, color = rgb({0, 79.2, 23.1})},
        {grade = "C", accuracy = 70, color = rgb({93.7, 100, 27.5})},
        {grade = "D", accuracy = 0, color = rgb({70.6, 28.6, 0})},
        {grade = "F", accuracy = 0, color = rgb({37.3, 0, 0})},

    }
end

return maniaGrades