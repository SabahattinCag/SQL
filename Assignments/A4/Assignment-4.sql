


-- Create a factorial function
CREATE FUNCTION dbo.CalculateFactorial (@n INT)
RETURNS INT
AS
BEGIN
    DECLARE @result INT = 1;
    
    WHILE @n > 1
    BEGIN
        SET @result = @result * @n;
        SET @n = @n - 1;
    END
    
    RETURN @result;
END;

--- Call the function
SELECT dbo.CalculateFactorial(5);