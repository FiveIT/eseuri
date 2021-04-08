/// <reference types="cypress" />

describe('About', () => {
  it('shows the Bee Movie Script', () => {
    cy.visit('/about').contains('The Bee Movie Script')
  })

  it('connects successfully to the server and shows "sarmale cu ghimbir"', () => {
    cy.get('footer').contains('sarmale cu ghimbir')
  })
})
