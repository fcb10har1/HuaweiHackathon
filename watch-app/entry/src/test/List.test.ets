import localUnitTest from './LocalUnit.test';
import translationFeatureTest from './TranslationFeature.test';

export default function testsuite() {
  localUnitTest();
  translationFeatureTest();
}