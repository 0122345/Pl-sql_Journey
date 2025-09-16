
-- Step 1: Create tables with appropriate columns and constraints
-- ========================================

-- Students table
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    enrollment_date DATE NOT NULL,
    major VARCHAR(100),
    gpa DECIMAL(3,2) CHECK (gpa >= 0.0 AND gpa <= 4.0)
);

-- Courses table
CREATE TABLE courses (
    course_id INT PRIMARY KEY,
    course_code VARCHAR(10) UNIQUE NOT NULL,
    course_name VARCHAR(200) NOT NULL,
    credits INT NOT NULL CHECK (credits > 0),
    department VARCHAR(100) NOT NULL,
    instructor_name VARCHAR(100)
);

-- Enrollments table (junction table for many-to-many relationship)
CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    enrollment_date DATE NOT NULL,
    grade CHAR(2) CHECK (grade IN ('A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F')),
    semester VARCHAR(20) NOT NULL,
    year INT NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
    UNIQUE(student_id, course_id, semester, year)
);

-- Insert sample data
-- ========================================

-- Sample students
INSERT INTO students VALUES 
(1, 'John', 'Smith', 'john.smith@email.com', '2023-09-01', 'SOftware Engineering', 3.8),
(2, 'Emma', 'Johnson', 'emma.johnson@email.com', '2023-09-01', 'Mathematics', 3.9),
(3, 'Michael', 'Brown', 'michael.brown@email.com', '2023-09-01', 'SOftware Engineering', 3.7),
(4, 'Sarah', 'Davis', 'sarah.davis@email.com', '2024-01-15', 'Physics', 3.6),
(5, 'David', 'Wilson', 'david.wilson@email.com', '2024-01-15', 'Mathematics', 3.5);

-- Sample courses
INSERT INTO courses VALUES 
(101, 'CS101', 'Introduction to Programming', 3, 'SOftware Engineering', 'Dr. Anderson'),
(102, 'MATH201', 'Calculus II', 4, 'Mathematics', 'Prof. Thompson'),
(103, 'CS201', 'Data Structures', 3, 'SOftware Engineering', 'Dr. Lee'),
(104, 'PHYS101', 'General Physics I', 4, 'Physics', 'Dr. Martinez'),
(105, 'MATH301', 'Linear Algebra', 3, 'Mathematics', 'Prof. Garcia');

-- Sample enrollments
INSERT INTO enrollments VALUES 
(1, 1, 101, '2023-09-01', 'A', 'Fall', 2023),
(2, 1, 102, '2023-09-01', 'B+', 'Fall', 2023),
(3, 2, 102, '2023-09-01', 'A+', 'Fall', 2023),
(4, 2, 105, '2023-09-01', 'A', 'Fall', 2023),
(5, 3, 101, '2023-09-01', 'A-', 'Fall', 2023),
(6, 3, 103, '2024-01-15', 'B', 'Spring', 2024),
(7, 4, 104, '2024-01-15', 'B+', 'Spring', 2024),
(8, 5, 102, '2024-01-15', 'A-', 'Spring', 2024);

-- Step 2: Different types of joins
-- ========================================

-- INNER JOIN: Get all students with their enrolled courses
SELECT 
    s.student_id,
    s.first_name,
    s.last_name,
    c.course_code,
    c.course_name,
    e.grade,
    e.semester,
    e.year
FROM students s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN courses c ON e.course_id = c.course_id
ORDER BY s.last_name, s.first_name;

-- LEFT JOIN: Get all students, including those not enrolled in any course
SELECT 
    s.student_id,
    s.first_name,
    s.last_name,
    s.major,
    COUNT(e.enrollment_id) as total_enrollments
FROM students s
LEFT JOIN enrollments e ON s.student_id = e.student_id
GROUP BY s.student_id, s.first_name, s.last_name, s.major
ORDER BY total_enrollments DESC;

-- RIGHT JOIN: Get all courses, including those with no students enrolled
SELECT 
    c.course_id,
    c.course_code,
    c.course_name,
    c.department,
    COUNT(e.enrollment_id) as enrolled_students
FROM enrollments e
RIGHT JOIN courses c ON e.course_id = c.course_id
GROUP BY c.course_id, c.course_code, c.course_name, c.department
ORDER BY enrolled_students DESC;

-- FULL OUTER JOIN: Complete view of students and courses relationship
-- Note: MySQL doesn't support FULL OUTER JOIN directly, so we use UNION
SELECT 
    s.first_name,
    s.last_name,
    c.course_code,
    c.course_name,
    e.grade
FROM students s
LEFT JOIN enrollments e ON s.student_id = e.student_id
LEFT JOIN courses c ON e.course_id = c.course_id

UNION

SELECT 
    s.first_name,
    s.last_name,
    c.course_code,
    c.course_name,
    e.grade
FROM students s
RIGHT JOIN enrollments e ON s.student_id = e.student_id
RIGHT JOIN courses c ON e.course_id = c.course_id;

-- Step 3: Create indexes to optimize query performance
-- ========================================

-- Index on frequently searched columns
CREATE INDEX idx_student_email ON students(email);
CREATE INDEX idx_student_major ON students(major);
CREATE INDEX idx_course_code ON courses(course_code);
CREATE INDEX idx_course_department ON courses(department);

-- Composite indexes for common query patterns
CREATE INDEX idx_enrollment_student_course ON enrollments(student_id, course_id);
CREATE INDEX idx_enrollment_semester_year ON enrollments(semester, year);
CREATE INDEX idx_enrollment_grade ON enrollments(grade);

-- Index for date range queries
CREATE INDEX idx_student_enrollment_date ON students(enrollment_date);

-- Step 4: Create views to simplify data access
-- ========================================

-- View 1: Student Course Summary
CREATE VIEW student_course_summary AS
SELECT 
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS full_name,
    s.major,
    s.gpa,
    COUNT(e.enrollment_id) as total_courses,
    AVG(
        CASE e.grade
            WHEN 'A+' THEN 4.0
            WHEN 'A' THEN 4.0
            WHEN 'A-' THEN 3.7
            WHEN 'B+' THEN 3.3
            WHEN 'B' THEN 3.0
            WHEN 'B-' THEN 2.7
            WHEN 'C+' THEN 2.3
            WHEN 'C' THEN 2.0
            WHEN 'C-' THEN 1.7
            WHEN 'D+' THEN 1.3
            WHEN 'D' THEN 1.0
            WHEN 'F' THEN 0.0
            ELSE NULL
        END
    ) as calculated_gpa
FROM students s
LEFT JOIN enrollments e ON s.student_id = e.student_id
GROUP BY s.student_id, s.first_name, s.last_name, s.major, s.gpa;

-- View 2: Course Enrollment Statistics
CREATE VIEW course_enrollment_stats AS
SELECT 
    c.course_id,
    c.course_code,
    c.course_name,
    c.department,
    c.credits,
    COUNT(e.enrollment_id) as total_enrollments,
    AVG(
        CASE e.grade
            WHEN 'A+' THEN 4.0
            WHEN 'A' THEN 4.0
            WHEN 'A-' THEN 3.7
            WHEN 'B+' THEN 3.3
            WHEN 'B' THEN 3.0
            WHEN 'B-' THEN 2.7
            WHEN 'C+' THEN 2.3
            WHEN 'C' THEN 2.0
            WHEN 'C-' THEN 1.7
            WHEN 'D+' THEN 1.3
            WHEN 'D' THEN 1.0
            WHEN 'F' THEN 0.0
            ELSE NULL
        END
    ) as average_grade_points
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_code, c.course_name, c.department, c.credits;

-- View 3: Department Performance Overview
CREATE VIEW department_overview AS
SELECT 
    c.department,
    COUNT(DISTINCT c.course_id) as total_courses,
    COUNT(e.enrollment_id) as total_enrollments,
    AVG(
        CASE e.grade
            WHEN 'A+' THEN 4.0
            WHEN 'A' THEN 4.0
            WHEN 'A-' THEN 3.7
            WHEN 'B+' THEN 3.3
            WHEN 'B' THEN 3.0
            WHEN 'B-' THEN 2.7
            WHEN 'C+' THEN 2.3
            WHEN 'C' THEN 2.0
            WHEN 'C-' THEN 1.7
            WHEN 'D+' THEN 1.3
            WHEN 'D' THEN 1.0
            WHEN 'F' THEN 0.0
            ELSE NULL
        END
    ) as department_avg_gpa
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.department
ORDER BY department_avg_gpa DESC;

-- Step 5: Sample queries using the views
-- ========================================

-- Query using student_course_summary view
SELECT * FROM student_course_summary 
WHERE total_courses >= 2 
ORDER BY calculated_gpa DESC;

-- Query using course_enrollment_stats view
SELECT * FROM course_enrollment_stats 
WHERE total_enrollments > 0 
ORDER BY average_grade_points DESC;

-- Query using department_overview view
SELECT * FROM department_overview 
ORDER BY total_enrollments DESC;