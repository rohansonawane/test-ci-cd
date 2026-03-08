package com.rohan.cicd;

import org.junit.Assert;
import org.junit.Test;

public class AppTest {
  @Test
  public void buildMessageShouldMatchExpectedText() {
    Assert.assertEquals("CI/CD assignment app is running", App.buildMessage());
  }
}
