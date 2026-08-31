#!/usr/bin/env Rscript
# Four ways to classify the same 9,402 people, scored the same way.
# EXPLORATORY. Writes only to exploration/.
suppressPackageStartupMessages({library(dplyr); library(survival); library(MASS)})
OUT <- file.path("exploration", "four_schemas"); dir.create(OUT, recursive=TRUE, showWarnings=FALSE)
source("config_paths.R")
read_any <- function(p,...){h<-readLines(p,n=1,warn=FALSE)
  read.delim(p,sep=if(grepl("\t",h))"\t" else ",",stringsAsFactors=FALSE,...)}
bpid <- function(df,l){c1<-c(ID_COL,paste0(ID_COL,".x"),paste0(ID_COL,".y"))
  h<-c1[c1 %in% names(df)]; if(!length(h)) stop(l); df$pid<-as.character(df[[h[1]]]); df}
esi<-bpid(read_any(ESI_PATH),"E"); phe<-bpid(read_any(PHE_PATH,na.strings=c("","NA")),"P")
phe<-phe[!(!is.na(phe$cohort)&trimws(phe$cohort)=="ILD/Brnch"),]
vs<-bpid(read_any(VS_PATH),"V"); cod<-bpid(read_any(COD_PATH),"C"); ex<-bpid(read_any(EX_PATH),"X")
u<-suppressWarnings(as.integer(cod$Torch_Group_Basic)); cod$UCD_Resp<-as.integer(!is.na(u)&u==1L)
ev1<-esi%>%filter(visitnum==1,PrePost==1)%>%group_by(pid)%>%
  summarise(ESI=mean(ESI,na.rm=TRUE),.groups="drop")
d<-ev1%>%inner_join(phe%>%filter(visitnum==1),by="pid")%>%
  mutate(gender=factor(gender),race=factor(race),SmokCigNow=factor(SmokCigNow),
         afl=FEV1_FVC_post<0.70, emph=CT_Visual_Emph_Severity>=1,
         wall=CT_Visual_Wall_Thickening==2, dysp=MMRCDyspneaScor>=2,
         qol=SGRQ_scoreTotal>=25, cb=Chronic_Bronchitis==1)%>%
  filter(!is.na(afl),!is.na(emph),!is.na(wall),!is.na(dysp),!is.na(qol),!is.na(cb),!is.na(ESI))
stopifnot(nrow(d)==9402L)
om<-d$dysp+d$qol+d$cb; nbb<-d$emph+d$wall+om
es<-ifelse(d$ESI>=2.5,2,ifelse(d$ESI>=1.0,1,0))
ORD<-c("noCOPD","AFL-only-NoCOPD","COPD-minor","COPD-major")
mk<-function(minor,aflonly) factor(ifelse(d$afl&!aflonly,"COPD-major",
  ifelse(d$afl&aflonly,"AFL-only-NoCOPD",ifelse(!d$afl&minor,"COPD-minor","noCOPD"))),levels=ORD)
d$S1<-mk(nbb>=3, nbb==0)                       # MD-COPD with CT (reference)
d$S2<-mk((es+om)>=3, (es+om)==0)               # MD-COPD with ESI, published thresholds
d$S3<-mk(om>=2, om==0)                         # MD-COPD, symptoms only, no structural criterion
d$S0<-factor(ifelse(d$afl,"COPD","noCOPD"),levels=c("noCOPD","COPD"))  # fixed ratio
COV<-"age_visit + gender + race + SmokCigNow + ATS_PackYears + BMI"
mort<-d%>%inner_join(vs%>%dplyr::select(pid,vital_status,days_followed),by="pid")%>%
  left_join(cod%>%dplyr::select(pid,UCD_Resp),by="pid")%>%
  mutate(ev_resp=ifelse(vital_status==1&!is.na(UCD_Resp)&UCD_Resp==1,1,0),py=days_followed/365.25)%>%
  filter(complete.cases(age_visit,gender,race,SmokCigNow,ATS_PackYears,BMI))
pr<-phe%>%filter(visitnum==1)%>%transmute(pid,prior_exac=suppressWarnings(as.numeric(Exacerbation_Frequency)))%>%
  distinct(pid,.keep_all=TRUE)
exa<-d%>%inner_join(ex%>%dplyr::select(pid,Total_Exacerbations,Years_Followed),by="pid")%>%
  left_join(pr,by="pid")%>%filter(!is.na(Total_Exacerbations),Years_Followed>0,!is.na(prior_exac),
  complete.cases(age_visit,gender,race,SmokCigNow,ATS_PackYears,BMI))

cat("################ PART 1: how each schema labels the same 9,402 people ################\n\n")
for(s in c("S0","S1","S2","S3")){
  lab<-c(S0="S0  fixed ratio (FEV1/FVC < 0.70 only)",
         S1="S1  MD-COPD with CT   [reference]",
         S2="S2  MD-COPD with ESI, published thresholds",
         S3="S3  MD-COPD, symptoms only, no structural criterion")[s]
  cat(sprintf("%-52s ",lab)); print(table(d[[s]]))
}
cat("\n################ PART 2: risk within each schema's own categories ################\n")
for(s in c("S0","S1","S2","S3")){
  cat(sprintf("\n=== %s ===\n",s))
  f1<-as.formula(sprintf("Surv(py, vital_status) ~ %s + %s",s,COV))
  f2<-as.formula(sprintf("Surv(py, ev_resp) ~ %s + %s",s,COV))
  m1<-coxph(f1,data=mort); m2<-coxph(f2,data=mort)
  n1<-glm.nb(as.formula(paste("Total_Exacerbations ~",s,"+",COV,
      "+ prior_exac + offset(log(Years_Followed))")),data=exa)
  cm<-summary(m1)$conf.int; cr<-summary(m2)$conf.int; ce<-summary(n1)$coef
  cat(sprintf("  %-16s %6s %8s %26s %24s %24s\n","category","n","deaths",
      "all-cause HR (95% CI)","resp HR (95% CI)","exac IRR (95% CI)"))
  for(g in levels(d[[s]])){
    ix<-mort[[s]]==g; r<-paste0(s,g)
    f<-function(M) if(r %in% rownames(M)) sprintf("%.2f (%.2f-%.2f)",M[r,1],M[r,3],M[r,4]) else "reference"
    fe<-if(r %in% rownames(ce)) sprintf("%.2f (%.2f-%.2f)",exp(ce[r,1]),
          exp(ce[r,1]-1.96*ce[r,2]),exp(ce[r,1]+1.96*ce[r,2])) else "reference"
    cat(sprintf("  %-16s %6d %8d %26s %24s %24s\n",g,sum(ix),sum(mort$vital_status[ix]),f(cm),f(cr),fe))
  }
  cat(sprintf("  C-index all-cause %.4f | respiratory %.4f | exacerbation AIC %.1f\n",
      summary(m1)$concordance[1],summary(m2)$concordance[1],AIC(n1)))
}
cat("\nwrote ",normalizePath(OUT),"\n")
