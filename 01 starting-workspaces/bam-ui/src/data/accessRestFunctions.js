import axios from "axios";

const serverUrl = "http://localhost:8083"

export const getAllAccessGroups = () => {
    return axios({url : `${serverUrl}/api/accessgroup`, method: "GET"})
}

export const getAccessGroup = (id) => {
    return axios({url :  `${serverUrl}/api/accessgroup/` + id, method: "GET"})
}

export const updateAccessGroupName = (id,name) => {
    return axios({url : `${serverUrl}/api/accessgroup/`+id, method: "PUT", data: {name: name}})
}

export const saveNewAccessGroup = (name) => {
    return axios({url : `${serverUrl}/api/accessgroup`, method: "POST", data: {name: name}})
}

export const addLocationToAccessGroup = (locationId, accessGroupId) => {
    return axios({url : `${serverUrl}/api/accessgroup/`+ accessGroupId + "/location/" + locationId, method: "POST", data: {ignore:"ignore"}})
}

export const addUserToAccessGroup = (userId, accessGroupId) => {
    return axios({url : `${serverUrl}/api/accessgroup/` + accessGroupId + "/user/" + userId, method: "POST", data: {ignore:"ignore"}})
}
export const removeLocationFromAccessGroup = (locationId, accessGroupId) => {
    return axios({url : `${serverUrl}/api/accessgroup/`+ accessGroupId + "/location/" + locationId, method: "DELETE"})
}

export const removeUserFromAccessGroup = (userId, accessGroupId) => {
    return axios({url : `${serverUrl}/api/accessgroup/` + accessGroupId + "/user/" + userId, method: "DELETE"})
}

export const getUser = (id) => {
    return axios({url : `${serverUrl}/api/accessgroupuser/`+id, method: "GET"})
}
