package gqlqueries

const (
	WorksByPK = `query($id: Int!) {
	works_by_pk(id: $id) {
		id
		teacher_id
	}
}`

	InsertWork = `mutation($content: String!, $status: work_status_enum!, $requestedTeacherID: Int) {
	insert_works_one(object: {content: $content, status: $status, teacher_id: $requestedTeacherID}) {
		id
	}
}	
`
	insertEssay = `mutation($workID: Int!, $subjectID: Int!) {
	insert_essays_one(object: {work_id: $workID, title_id: $subjectID}) {
		__typename
	}
}`
	insertCharacterization = `mutation($workID: Int!, $subjectID: Int!) {
	insert_characterizations_one(object: {work_id: $workID, character_id: $subjectID}) {
		__typename
	}
`
	InsertTeacher = `mutation($email: citext!, $auth0ID: String!){
  insert_users_one(object: {email: $email, auth0_id: $auth0ID, role: "teacher"}) {
    id
  }
}
`
	//nolint:lll
	RegisterUser = `mutation($userID: Int!, $firstName: String!, $middleName: String, $lastName: String!, $schoolID: Int!) {
  update_users(where: {id: {_eq: $userID}}, _set: {first_name: $firstName, middle_name: $middleName, last_name: $lastName, school_id: $schoolID}) {
    affected_rows
  }
}
`

	Clear = `mutation Clear {
	delete_works(where: {}) {
		affected_rows
	}
	delete_teachers(where: {}) {
		affected_rows
	}
	delete_students(where: {}) {
		affected_rows
	}
	delete_users_all(where: {}) {
		affected_rows
	}
}`
)

//nolint:gochecknoglobals
var (
	InsertWorkSupertype = map[string]string{
		"essay":            insertEssay,
		"characterization": insertCharacterization,
	}
)

type InsertWorkOutput struct {
	Query struct {
		ID int `json:"id"`
	} `json:"insert_works_one"`
}

type InsertTeacherOutput struct {
	Query struct {
		ID int `json:"id"`
	} `json:"insert_users_one"`
}

type WorksByPKOutput struct {
	Query struct {
		ID        int `json:"id"`
		TeacherID int `json:"teacher_id"`
	} `json:"works_by_pk"`
}
